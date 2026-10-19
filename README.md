# JUpdater for Flutter

Update checker for Flutter apps on **Android, iOS, macOS, Windows and Linux**.
It asks your server (managed or self-hosted) whether a newer build exists and
shows a ready-made, responsive **blocking screen** (forced update) or **bottom
sheet** (optional update). Everything can be replaced with your own widgets.

* Zero third-party dependencies (Flutter SDK only) - no diamond-dependency problems.
* Web is intentionally not supported: a web app updates when you deploy it.

## Install

**From pub.dev** (after you publish it, see `docs/PUBLISHING.md`):

```yaml
dependencies:
  jupdater: ^1.0.0
```

**From a copied folder** (no pub.dev needed): copy this whole folder into your project, e.g. `packages/jupdater`, then:

```yaml
dependencies:
  jupdater:
    path: packages/jupdater
```

## Use

```dart
import 'package:flutter/material.dart';
import 'package:jupdater/jupdater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JUpdater.instance.init(
    JUpdaterConfig.managed(apiKey: 'YOUR_API_KEY'),
    // or: JUpdaterConfig.custom(serverUrl: 'https://api.example.com/check-update'),
  );

  runApp(JUpdater.instance.wrap(const MyApp())); // wrap() lets the overlay cover the whole app
}
```

`wrap()` is required for the built-in screens: Flutter has no global overlay
without a widget in the tree, and this must sit *above* `MaterialApp` so it can
cover every route.

### What happens

* App start and every return to the foreground (throttled, default 10 min) trigger a check.
* **Forced update** (`force_update: true`, or `is_blocked: true`): an opaque screen covers the app; touches, focus, screen readers and the Android back button cannot reach the app underneath. A cached forced update blocks immediately on the next launch, before the network answers. Close app is hidden on iOS (apps must not quit themselves).
* **Optional update**: a bottom sheet with *Later* and *Update*.

### "Later" behaviour

```dart
JUpdaterConfig.managed(
  apiKey: '...',
  laterBehavior: LaterBehavior.snooze,       // or LaterBehavior.dismiss (default)
  snoozeDuration: const Duration(hours: 24), // used by snooze
)
```

* `dismiss`: hidden until the next app launch.
* `snooze`: hidden for `snoozeDuration`, stored on the device, reset by a newer release.
* A forced update can never be dismissed or snoozed.

### Listener

```dart
JUpdater.instance.onUpdateCheckComplete = (UpdateResult result) {
  // result.updateAvailable, result.forceUpdate, result.updateUrl,
  // result.title, result.message, result.isSnoozed, result.fromCache ...
};
// or: JUpdater.instance.results.listen((r) { ... });
```

It fires after every completed check, also when there is no update and also
while snoozed (`isSnoozed == true`; the built-in sheet stays hidden).

### Your own UI

```dart
JUpdaterConfig.managed(
  apiKey: '...',
  blockingBuilder: (context, result, actions) => MyBlockingScreen(result, actions), // full screen
  sheetBuilder: (context, result, actions) => MySheetContent(result, actions),      // sheet content only
  // showDefaultUi: false,  // build everything yourself from the listener
);
```

`actions` offers `update()`, `later()`, `closeApp()`, `canCloseApp`, `hasUpdateUrl`.
Custom widgets render above your Navigator, so use `actions` rather than `Navigator`.
`checkNow()` runs a check on demand.

## Platform notes

| Platform | App id sent as `pid` | Notes |
|---|---|---|
| Android | applicationId | Adds the `INTERNET` permission automatically. |
| iOS | bundle id | `CFBundleVersion` must be an integer build number. |
| macOS | bundle id | Add the **network client** entitlement (`com.apple.security.network.client`) to `DebugProfile.entitlements` and `Release.entitlements`. |
| Windows / Linux | `name` from `pubspec.yaml` | Read from `data/flutter_assets/version.json`. If missing, set `appIdOverride`, `appBuildNumberOverride` (and `appVersionNameOverride`) in `JUpdaterConfig`. |

The build number is the part after `+` in your `pubspec.yaml` version (`1.2.0+34` -> 34).
Fuchsia and web: the SDK disables itself and logs a message.

## Security

* Server URL must be `https` (`allowInsecureHttp` only for local testing, custom server only).
* Redirects are not followed; responses are limited to 64 KB; timeouts everywhere.
* Responses are validated: `pid` must equal the app id, `version_code` must be a number, the update URL must use an allow-listed scheme (https, market, itms-apps, macappstore, ms-windows-store, snap, appstream) and may be restricted further with `allowedUpdateHosts`.
* Title and message are limited (100 / 500 characters), stripped of control and bidi-override characters and shown as plain text only.
* A random nonce is sent with each request; if your server echoes it, a mismatch rejects the reply (replay protection).
* TLS errors never fall back to cached data. Optional certificate pinning via `pinnedCertificatePem`.
* The API key ships inside your app, so treat it as an identifier, not a secret: restrict it server-side (package id, rate limits).

## Privacy / GDPR / ePrivacy

For each check the SDK sends: `uid` (random id generated on first run, not derived from any device identifier),
`platform`, `brand`, `device`, `os_version`, `model`, `manufacturer`, `mainboard`, `country`, `package_name`,
`app_version_code`, `app_version_name`, `firstInstallTime`, `build_number` (the SDK version) and the API key.
No advertising id and no Android ID is collected.

**You, the app developer, are responsible** for disclosing this in your privacy policy (and in store
privacy forms such as Google Play Data safety / Apple privacy labels) and for having a legal basis
where the GDPR or ePrivacy rules apply.

## Backend

See `docs/BACKEND_CONTRACT.md` for the request/response format your server must implement.
