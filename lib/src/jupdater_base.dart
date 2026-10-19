import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/native_bridge.dart';
import 'core/platform_info.dart';
import 'core/random_ids.dart';
import 'core/server_response.dart';
import 'core/storage.dart';
import 'core/update_client.dart';
import 'core/update_logic.dart';
import 'models/jupdater_config.dart';
import 'models/update_actions.dart';
import 'models/update_result.dart';
import 'ui/jupdater_host.dart';
import 'ui/ui_state.dart';
import 'version.dart';

/// Entry point of the SDK.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await JUpdater.instance.init(JUpdaterConfig.managed(apiKey: 'KEY'));
///   runApp(JUpdater.instance.wrap(const MyApp()));
/// }
/// ```
class JUpdater {
  JUpdater._();

  static final JUpdater instance = JUpdater._();

  JUpdaterConfig? _config;
  JPlatformInfo? _info;
  JStorage? _storage;
  UpdateClient? _client;
  bool _initialized = false;
  Future<UpdateResult?>? _inFlight;
  DateTime? _lastAttempt;
  UpdateResult? _lastResult;
  DateTime? _lastBackPress;
  Timer? _backHintTimer;
  final Set<int> _dismissedThisSession = <int>{};
  late final _JObserver _observer = _JObserver(this);
  final StreamController<UpdateResult> _results =
      StreamController<UpdateResult>.broadcast();

  /// Called after every completed check (also when no update exists and also
  /// while an update is snoozed - see [UpdateResult.isSnoozed]).
  ///
  /// ```dart
  /// JUpdater.instance.onUpdateCheckComplete = (result) {
  ///   if (result.forceUpdate) { /* your blocking UI */ }
  /// };
  /// ```
  void Function(UpdateResult result)? onUpdateCheckComplete;

  /// Same events as [onUpdateCheckComplete], as a broadcast stream.
  Stream<UpdateResult> get results => _results.stream;

  /// Result of the most recent check, if any.
  UpdateResult? get lastResult => _lastResult;

  bool get isInitialized => _initialized;

  /// Internal: current overlay state, listened to by [JUpdaterHost].
  final ValueNotifier<UpdateUiState> uiState =
      ValueNotifier<UpdateUiState>(UpdateUiState.none);

  /// Internal: shows "press back again to exit" on the blocking screen.
  final ValueNotifier<bool> backHintVisible = ValueNotifier<bool>(false);

  /// Internal: active configuration.
  JUpdaterConfig? get config => _config;

  /// Initialises the SDK and starts the first check in the background.
  ///
  /// Call once, as early as possible in `main()`. Misconfiguration throws
  /// (from [JUpdaterConfig]); runtime problems (no network, bad response) are
  /// logged and never crash the app. Does nothing on web and unsupported platforms.
  Future<void> init(JUpdaterConfig config) async {
    if (_initialized) {
      _log('init() called twice - ignored');
      return;
    }
    if (kIsWeb) {
      debugPrint('[JUpdater] Web is not supported - SDK disabled.');
      return;
    }
    WidgetsFlutterBinding.ensureInitialized();
    _config = config;

    try {
      final info = await PlatformInfoLoader.load(config);
      if (info == null) {
        _error('Unsupported platform - SDK disabled.');
        return;
      }
      if (info.packageName.isEmpty || info.buildNumber <= 0) {
        _error('Could not detect app id / build number on ${info.platform}. '
            'Set appIdOverride and appBuildNumberOverride in JUpdaterConfig. SDK disabled.');
        return;
      }
      _info = info;
      _storage = await JStorage.open(info.supportDir);
      _client = UpdateClient(config);
      _initialized = true;
      WidgetsBinding.instance.addObserver(_observer);
      _log('Initialised ($jupdaterSdkName v$jupdaterSdkVersion) on ${info.platform}, '
          'app ${info.packageName} build ${info.buildNumber}');
      _restoreBlockingFromCache();
      unawaited(_check(respectThrottle: false));
    } catch (e) {
      _error('Init failed: $e');
    }
  }

  /// Wraps your app so the update overlay can cover it completely. Pass the
  /// widget you would give to `runApp`.
  Widget wrap(Widget child) => JUpdaterHost(child: child);

  /// Runs a check now (ignores the throttle). Returns `null` if the check failed
  /// or the SDK is not initialised.
  Future<UpdateResult?> checkNow() => _check(respectThrottle: false);

  /// Builds the action set for an [UpdateResult] (used by the UI layer).
  UpdateActions actionsFor(UpdateResult result) {
    return UpdateActions(
      update: () => _openUpdate(result),
      later: () => _later(result),
      closeApp: _closeApp,
      canCloseApp: _canCloseApp,
      hasUpdateUrl: result.updateUrl != null,
    );
  }

  // ---------------------------------------------------------------- checking

  Future<UpdateResult?> _check({required bool respectThrottle}) {
    if (!_initialized) return Future<UpdateResult?>.value(null);
    final running = _inFlight;
    if (running != null) return running;

    final cfg = _config!;
    if (respectThrottle) {
      final last = _lastAttempt;
      if (last != null &&
          DateTime.now().difference(last) < cfg.minCheckInterval) {
        return Future<UpdateResult?>.value(null);
      }
    }
    final future = _doCheck().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<UpdateResult?> _doCheck() async {
    _lastAttempt = DateTime.now();
    final cfg = _config!;
    final info = _info!;
    final storage = _storage!;

    ServerResponse? response;
    var fromCache = false;

    try {
      final nonce = randomHex(16);
      final body = await _client!.fetch(
        payload: _payload(cfg, info, storage),
        packageName: info.packageName,
        versionCode: info.buildNumber,
        platform: info.platform,
        nonce: nonce,
      );
      final parsed = ServerResponse.parse(
        body,
        allowedHosts: cfg.allowedUpdateHosts,
        expectedNonce: nonce,
      );
      if (parsed.pid != info.packageName) {
        throw const FormatException('Package name mismatch');
      }
      response = parsed;
      unawaited(storage.saveCachedResponse(parsed.toJson()));
    } on UpdateNetworkException catch (e) {
      _log('Network problem (${e.message}) - trying offline cache');
      response = _cachedResponse();
      fromCache = response != null;
    } catch (e) {
      // Security or format problem: do not trust anything, do not use the cache.
      _error('Update check rejected: $e');
      return null;
    }

    if (response == null) return null;
    return _finish(response, fromCache);
  }

  Map<String, dynamic> _payload(
      JUpdaterConfig cfg, JPlatformInfo info, JStorage storage) {
    final installMs =
        info.firstInstallTimeMs > 0 ? info.firstInstallTimeMs : storage.firstSeenMs;
    // Same keys as the Android SDK, plus "platform".
    return <String, dynamic>{
      'uid': storage.installationId,
      'apiKey': cfg.apiKey,
      'build_number': jupdaterSdkVersion,
      'platform': info.platform,
      'brand': info.brand,
      'device': info.device,
      'os_version': info.osVersion,
      'model': info.model,
      'manufacturer': info.manufacturer,
      'mainboard': info.board,
      'country': info.country,
      'package_name': info.packageName,
      'app_version_code': info.buildNumber.toString(),
      'app_version_name': info.versionName,
      'firstInstallTime': formatInstallTime(installMs),
    };
  }

  ServerResponse? _cachedResponse() {
    final raw = _storage?.cachedResponse;
    if (raw == null) return null;
    try {
      final r = ServerResponse.fromMap(raw,
          allowedHosts: _config!.allowedUpdateHosts);
      return r.pid == _info!.packageName ? r : null;
    } catch (_) {
      return null;
    }
  }

  UpdateResult _finish(ServerResponse response, bool fromCache) {
    final cfg = _config!;
    var result = UpdateLogic.evaluate(
      response: response,
      currentVersionCode: _info!.buildNumber,
      platform: _info!.platform,
      fromCache: fromCache,
      fallbackTitle: cfg.texts.fallbackTitle,
      fallbackMessage: cfg.texts.fallbackMessage,
    );
    if (result.updateAvailable &&
        !result.forceUpdate &&
        _isSuppressed(result.latestVersionCode)) {
      result = result.copyWith(isSnoozed: true);
    }
    _updateUi(result);
    _lastResult = result;
    try {
      onUpdateCheckComplete?.call(result);
    } catch (e) {
      _error('onUpdateCheckComplete threw: $e');
    }
    if (!_results.isClosed) _results.add(result);
    return result;
  }

  bool _isSuppressed(int versionCode) {
    if (_config!.laterBehavior == LaterBehavior.snooze) {
      final until = _storage!.snoozedUntil(versionCode);
      return until != null && DateTime.now().millisecondsSinceEpoch < until;
    }
    return _dismissedThisSession.contains(versionCode);
  }

  /// A force update that was cached must block immediately on launch, before
  /// the network answers (otherwise the app is usable until the check ends).
  void _restoreBlockingFromCache() {
    final cached = _cachedResponse();
    if (cached == null) return;
    final cfg = _config!;
    final r = UpdateLogic.evaluate(
      response: cached,
      currentVersionCode: _info!.buildNumber,
      platform: _info!.platform,
      fromCache: true,
      fallbackTitle: cfg.texts.fallbackTitle,
      fallbackMessage: cfg.texts.fallbackMessage,
    );
    if (r.forceUpdate && _canShow(true)) {
      _setUi(UpdateUiState.blocking(r));
    }
  }

  // ---------------------------------------------------------------------- UI

  bool _canShow(bool force) {
    final cfg = _config!;
    return cfg.showDefaultUi ||
        (force ? cfg.blockingBuilder != null : cfg.sheetBuilder != null);
  }

  void _updateUi(UpdateResult r) {
    final needsUi = r.forceUpdate || (r.updateAvailable && !r.isSnoozed);
    if (!needsUi || !_canShow(r.forceUpdate)) {
      _setUi(UpdateUiState.none);
      return;
    }
    _setUi(r.forceUpdate
        ? UpdateUiState.blocking(r)
        : UpdateUiState.sheet(r));
  }

  void _setUi(UpdateUiState next) {
    if (uiState.value.sameAs(next)) return;
    uiState.value = next;
    if (next.kind != UpdateUiKind.blocking) {
      _backHintTimer?.cancel();
      backHintVisible.value = false;
    }
  }

  // ----------------------------------------------------------------- actions

  Future<bool> _openUpdate(UpdateResult r) async {
    final url = r.updateUrl;
    final info = _info;
    if (url == null || info == null) return false;
    final ok = await NativeBridge.openUrl(url, info.platform);
    if (!ok) _error('Could not open the update URL.');
    return ok;
  }

  void _later(UpdateResult r) {
    if (r.forceUpdate) return; // a forced update can never be postponed
    final cfg = _config;
    final storage = _storage;
    if (cfg == null || storage == null) return;
    if (cfg.laterBehavior == LaterBehavior.snooze) {
      final until =
          DateTime.now().add(cfg.snoozeDuration).millisecondsSinceEpoch;
      unawaited(storage.setSnooze(r.latestVersionCode, until));
    } else {
      _dismissedThisSession.add(r.latestVersionCode);
    }
    _setUi(UpdateUiState.none);
  }

  bool get _canCloseApp => _info?.platform != 'ios';

  void _closeApp() {
    switch (_info?.platform) {
      case 'android':
        unawaited(SystemNavigator.pop());
        break;
      case 'macos':
      case 'windows':
      case 'linux':
        unawaited(
            ServicesBinding.instance.exitApplication(AppExitType.required));
        break;
      default:
        break; // iOS: apps must not terminate themselves
    }
  }

  // ------------------------------------------------------ lifecycle / back key

  void _onResumed() {
    unawaited(_check(respectThrottle: true));
  }

  Future<bool> _handleBack() async {
    final state = uiState.value;
    switch (state.kind) {
      case UpdateUiKind.none:
        return false;
      case UpdateUiKind.sheet:
        final r = state.result;
        if (r != null) _later(r);
        return true;
      case UpdateUiKind.blocking:
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null &&
            now.difference(last) < const Duration(seconds: 2)) {
          _closeApp();
          return true;
        }
        _lastBackPress = now;
        backHintVisible.value = true;
        _backHintTimer?.cancel();
        _backHintTimer = Timer(const Duration(seconds: 2), () {
          backHintVisible.value = false;
        });
        return true; // swallow: the app underneath must not navigate
    }
  }

  // ----------------------------------------------------------------- logging

  void _log(String message) {
    if (_config?.debug ?? false) debugPrint('[JUpdater] $message');
  }

  void log(String message){
    _log(message);
  }

  void _error(String message) {
    debugPrint('[JUpdater] $message');
  }


  // Future<void> _logErrorBody(HttpClientResponse response) async {
  //   final builder = BytesBuilder(copy: false);
  //   var truncated = false;
  //   try {
  //     await for (final chunk in response) {
  //       final remaining = _maxResponseBytes - builder.length;
  //       builder.add(
  //         chunk.length > remaining ? chunk.sublist(0, remaining) : chunk,
  //       );
  //       if (chunk.length > remaining) {
  //         truncated = true;
  //         break;
  //       }
  //     }
  //   } finally {
  //     _log(
  //       'Response body: ${utf8.decode(builder.takeBytes(), allowMalformed: true)}'
  //           '${truncated ? ' [truncated at 64 KB]' : ''}',
  //     );
  //   }
  // }

}

class _JObserver with WidgetsBindingObserver {
  _JObserver(this._owner);

  final JUpdater _owner;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _owner._onResumed();
  }

  @override
  Future<bool> didPopRoute() => _owner._handleBack();
}
