# JUpdater example

The platform folders (android, ios, macos, windows, linux) are not included.
Generate them once, then run:

```bash
cd example
flutter create --platforms=android,ios,macos,windows,linux .
flutter run
```

* Replace `YOUR_API_KEY` in `lib/main.dart`.
* macOS: add `com.apple.security.network.client` to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
