# Distribution: two ways

## A) Copy the folder into a project (no pub.dev)

1. Copy this folder to `<your_app>/packages/jupdater/`.
2. In your app's `pubspec.yaml`:
   ```yaml
   dependencies:
     jupdater:
       path: packages/jupdater
   ```
3. `flutter pub get`.

You can also share it as a zip/Git repo and use a git dependency:

```yaml
dependencies:
  jupdater:
    git:
      url: https://github.com/qtlws/jupdater-flutter-sdk
      ref: v1.0.0
      # path: flutter   # if the package lives in a sub-folder of the repo
```

## B) Publish on pub.dev

1. Check the name is free: https://pub.dev/packages/jupdater. If taken, rename `name:` in `pubspec.yaml`,
   the `package:jupdater/...` imports in `test/` and `example/`, and the podspec/plugin names.
2. Fill in the real `homepage` / `repository` URLs in `pubspec.yaml`.
3. Add a `screenshots:` entry later if you like; keep `LICENSE` (MIT), `README.md`, `CHANGELOG.md`.
4. From the package folder:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   cd example && flutter pub get && flutter analyze && cd ..
   dart pub publish --dry-run     # fix every warning
   dart pub publish               # opens a Google sign-in; prefer a verified publisher
   ```
5. Tag the release in Git (`v1.0.0`). Later versions: bump `version:`, add a CHANGELOG entry, publish again.

Notes:
* pub.dev shows supported platforms from `pubspec.yaml` (Android, iOS, macOS, Windows, Linux; no web).
* A published version cannot be changed or deleted, only retracted/discontinued, so run the dry-run first.
* Build the example on each platform at least once before publishing (see `example/`).
