# Backend contract (JUpdater Flutter SDK)

## Request

### Managed server (`JUpdaterConfig.managed`)

`POST https://jupdater.qtlws.com/api/check-update?pid=<id>&version_code=<n>&platform=<p>&nonce=<hex>`

Headers: `x-api-key: <key>`, `Content-Type: application/json; charset=utf-8`

Body (all values are strings, same keys as the Android SDK, plus `platform`):

```json
{
  "uid": "random-uuid-per-installation",
  "apiKey": "YOUR_KEY",
  "build_number": "1.0.0",
  "platform": "android | ios | macos | windows | linux",
  "brand": "", "device": "", "os_version": "", "model": "",
  "manufacturer": "", "mainboard": "", "country": "",
  "package_name": "com.acme.app",
  "app_version_code": "34",
  "app_version_name": "1.2.0",
  "firstInstallTime": "2026-01-31_141500+0530"
}
```

* `build_number` is the **SDK** version (kept for compatibility with the Android SDK).
* `android_id` is no longer sent.
* `platform` is also in the query string, so a custom server can read it without a body.

### Custom server (`JUpdaterConfig.custom`)

`GET <serverUrl>?pid=<id>&version_code=<n>&platform=<p>&nonce=<hex>` (no body, no API key).

### What `platform` means for `pid`

| platform | `pid` / `package_name` |
|---|---|
| android | applicationId |
| ios, macos | bundle identifier |
| windows, linux | `name` in pubspec.yaml (or the SDK's `appIdOverride`) |

## Response (HTTP 200, JSON, max 64 KB)

```json
{
  "pid": "com.acme.app",
  "version_code": 40,
  "update_url": "https://apps.apple.com/app/id1234567890",
  "force_update": false,
  "is_blocked": false,
  "title": "Version 1.4 is here",
  "message": "Faster sync and a redesigned profile page.",
  "nonce": "<echo of the request nonce, optional>"
}
```

| Field | Required | Rules |
|---|---|---|
| `pid` | yes | Must equal the app id the SDK sent, otherwise the reply is rejected. |
| `version_code` | yes | Latest build number **for the requesting platform** (integer or numeric string). |
| `update_url` | yes when an update exists | **Platform-specific store URL** (see below). Allowed schemes only; otherwise ignored and the Update button is disabled. |
| `force_update` | recommended | `true` = blocking screen. If omitted, the legacy `force_update_gap` rule is used. |
| `force_update_gap` | legacy | Force when `version_code - installed >= gap`; `0` disables. Ignored when `force_update` is present. |
| `is_blocked` | optional | `true` = blocking screen even if no newer build exists. |
| `title` | optional | Max **100** characters. Plain text. Reject longer values when you save a release. |
| `message` | optional | Max **500** characters. Plain text, `\n` allowed. Reject longer values when you save a release. |
| `nonce` | optional | If present it must equal the request nonce. |

The SDK trims over-long text itself, but validate on your side too.

### Platform to `update_url` (backend task)

Choose the URL from the `platform` field of the request:

| platform | Example `update_url` |
|---|---|
| android | `https://play.google.com/store/apps/details?id=com.acme.app` or `market://details?id=com.acme.app` (or an APK URL) |
| ios | `https://apps.apple.com/app/id<APP_ID>` or `itms-apps://apps.apple.com/app/id<APP_ID>` |
| macos | `macappstore://apps.apple.com/app/id<APP_ID>` or a direct download `https://` URL |
| windows | `ms-windows-store://pdp/?productid=<STORE_ID>` or an installer `https://` URL |
| linux | `snap://<name>`, a Flatpak/AppImage `https://` URL, or your download page |

Allowed schemes: `https`, `market`, `itms-apps`, `itms-appss`, `macappstore`, `macappstores`,
`ms-windows-store`, `snap`, `appstream`. `http://` is rejected.

### Backend change list

1. Read `platform` (query string or body); validate it is one of the five values.
2. Store `version_code`, `update_url`, `force_update`, `is_blocked`, `title`, `message` **per app and per platform**.
3. Return the row for the requesting platform. If none exists, answer with a `version_code` that is not higher than the request's (no update).
4. Add `title` (<= 100) and `message` (<= 500) to the release form/API with validation.
5. Add the explicit `force_update` boolean (keep `force_update_gap` while old Android SDK versions are in the field).
6. Optionally echo `nonce`.
7. Bind API keys to the app id (`pid`) and rate-limit them.
8. Allow the new `platform` value in your analytics storage (the device fields are best-effort strings on desktop: for example `brand` = `Microsoft`/`Linux`, `model` = `desktop`).
