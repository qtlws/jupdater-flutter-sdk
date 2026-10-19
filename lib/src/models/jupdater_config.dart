import 'package:flutter/widgets.dart';

import '../core/url_validator.dart';
import 'update_actions.dart';
import 'update_result.dart';

/// What the "Later" button does on the (non-forced) update sheet.
enum LaterBehavior {
  /// Hide the sheet until the next app launch.
  dismiss,

  /// Hide the sheet for [JUpdaterConfig.snoozeDuration] (persisted on the device).
  /// A newer release resets the snooze.
  snooze,
}

/// Builds a custom update UI.
///
/// * For a forced update the returned widget fills the whole screen.
/// * For the sheet, the returned widget is the sheet *content*; the SDK
///   provides the scrim, slide animation and rounded container.
///
/// The widget is rendered above the app's own Navigator, so use the supplied
/// [UpdateActions] instead of Navigator calls.
typedef UpdateUiBuilder = Widget Function(
  BuildContext context,
  UpdateResult result,
  UpdateActions actions,
);

/// Optional header images that replace the ones shipped inside the SDK.
class JUpdaterImages {
  const JUpdaterImages({this.sheetHeader, this.blockingHeader});

  /// Shown full width on top of the update sheet (design for 1080 x 600 px).
  final ImageProvider? sheetHeader;

  /// Shown on top of the blocking screen (design for 1024 x 1024 px, 1:1).
  final ImageProvider? blockingHeader;
}

/// Texts used by the default screens (override to localise).
class JUpdaterTexts {
  const JUpdaterTexts({
    this.updateButton = 'Update',
    this.laterButton = 'Later',
    this.closeAppButton = 'Close app',
    this.backAgainHint = 'Press back again to exit',
    this.fallbackTitle = 'An update is available!',
    this.fallbackMessage =
        'A new version of this app is available. Please update to continue.',
  });

  final String updateButton;
  final String laterButton;
  final String closeAppButton;
  final String backAgainHint;

  /// Used when the server sends no (or an empty) title.
  final String fallbackTitle;

  /// Used when the server sends no (or an empty) message.
  final String fallbackMessage;
}

/// Configuration for [JUpdater.init].
class JUpdaterConfig {
  /// Managed server hosted by QTLWS.
  static const String managedServerUrl =
      'https://jupdater.qtlws.com/api/check-update';

  JUpdaterConfig._({
    required this.apiKey,
    required this.serverUrl,
    required this.laterBehavior,
    required this.snoozeDuration,
    required this.showDefaultUi,
    required this.blockingBuilder,
    required this.sheetBuilder,
    required this.texts,
    required this.images,
    required this.debug,
    required this.minCheckInterval,
    required this.requestTimeout,
    required this.allowedUpdateHosts,
    required this.allowInsecureHttp,
    required this.pinnedCertificatePem,
    required this.appIdOverride,
    required this.appVersionNameOverride,
    required this.appBuildNumberOverride,
  });

  /// Uses the managed server ([managedServerUrl]). Requests are POSTs that carry
  /// the device payload and the `x-api-key` header.
  factory JUpdaterConfig.managed({
    required String apiKey,
    LaterBehavior laterBehavior = LaterBehavior.dismiss,
    Duration snoozeDuration = const Duration(hours: 24),
    bool showDefaultUi = true,
    UpdateUiBuilder? blockingBuilder,
    UpdateUiBuilder? sheetBuilder,
    JUpdaterTexts texts = const JUpdaterTexts(),
    JUpdaterImages images = const JUpdaterImages(),
    bool debug = false,
    Duration minCheckInterval = const Duration(minutes: 10),
    Duration requestTimeout = const Duration(seconds: 15),
    List<String> allowedUpdateHosts = const <String>[],
    String? pinnedCertificatePem,
    String? appIdOverride,
    String? appVersionNameOverride,
    int? appBuildNumberOverride,
  }) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
    return JUpdaterConfig._create(
      apiKey: apiKey.trim(),
      serverUrl: managedServerUrl,
      laterBehavior: laterBehavior,
      snoozeDuration: snoozeDuration,
      showDefaultUi: showDefaultUi,
      blockingBuilder: blockingBuilder,
      sheetBuilder: sheetBuilder,
      texts: texts,
      images: images,
      debug: debug,
      minCheckInterval: minCheckInterval,
      requestTimeout: requestTimeout,
      allowedUpdateHosts: allowedUpdateHosts,
      allowInsecureHttp: false,
      pinnedCertificatePem: pinnedCertificatePem,
      appIdOverride: appIdOverride,
      appVersionNameOverride: appVersionNameOverride,
      appBuildNumberOverride: appBuildNumberOverride,
    );
  }

  /// Uses your own server. Requests are GETs with the query parameters
  /// `pid`, `version_code`, `platform` and `nonce`.
  factory JUpdaterConfig.custom({
    required String serverUrl,
    LaterBehavior laterBehavior = LaterBehavior.dismiss,
    Duration snoozeDuration = const Duration(hours: 24),
    bool showDefaultUi = true,
    UpdateUiBuilder? blockingBuilder,
    UpdateUiBuilder? sheetBuilder,
    JUpdaterTexts texts = const JUpdaterTexts(),
    JUpdaterImages images = const JUpdaterImages(),
    bool debug = false,
    Duration minCheckInterval = const Duration(minutes: 10),
    Duration requestTimeout = const Duration(seconds: 15),
    List<String> allowedUpdateHosts = const <String>[],
    bool allowInsecureHttp = false,
    String? pinnedCertificatePem,
    String? appIdOverride,
    String? appVersionNameOverride,
    int? appBuildNumberOverride,
  }) {
    return JUpdaterConfig._create(
      apiKey: null,
      serverUrl: serverUrl,
      laterBehavior: laterBehavior,
      snoozeDuration: snoozeDuration,
      showDefaultUi: showDefaultUi,
      blockingBuilder: blockingBuilder,
      sheetBuilder: sheetBuilder,
      texts: texts,
      images: images,
      debug: debug,
      minCheckInterval: minCheckInterval,
      requestTimeout: requestTimeout,
      allowedUpdateHosts: allowedUpdateHosts,
      allowInsecureHttp: allowInsecureHttp,
      pinnedCertificatePem: pinnedCertificatePem,
      appIdOverride: appIdOverride,
      appVersionNameOverride: appVersionNameOverride,
      appBuildNumberOverride: appBuildNumberOverride,
    );
  }

  factory JUpdaterConfig._create({
    required String? apiKey,
    required String serverUrl,
    required LaterBehavior laterBehavior,
    required Duration snoozeDuration,
    required bool showDefaultUi,
    required UpdateUiBuilder? blockingBuilder,
    required UpdateUiBuilder? sheetBuilder,
    required JUpdaterTexts texts,
    required JUpdaterImages images,
    required bool debug,
    required Duration minCheckInterval,
    required Duration requestTimeout,
    required List<String> allowedUpdateHosts,
    required bool allowInsecureHttp,
    required String? pinnedCertificatePem,
    required String? appIdOverride,
    required String? appVersionNameOverride,
    required int? appBuildNumberOverride,
  }) {
    if (snoozeDuration <= Duration.zero) {
      throw ArgumentError.value(
          snoozeDuration, 'snoozeDuration', 'must be greater than zero');
    }
    if (minCheckInterval.isNegative) {
      throw ArgumentError.value(
          minCheckInterval, 'minCheckInterval', 'must not be negative');
    }
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
          requestTimeout, 'requestTimeout', 'must be greater than zero');
    }
    final validatedUrl = UrlValidator.validateServerUrl(
      serverUrl,
      allowInsecureHttp: allowInsecureHttp,
    );
    return JUpdaterConfig._(
      apiKey: apiKey,
      serverUrl: validatedUrl,
      laterBehavior: laterBehavior,
      snoozeDuration: snoozeDuration,
      showDefaultUi: showDefaultUi,
      blockingBuilder: blockingBuilder,
      sheetBuilder: sheetBuilder,
      texts: texts,
      debug: debug,
      minCheckInterval: minCheckInterval,
      requestTimeout: requestTimeout,
      allowedUpdateHosts: List<String>.unmodifiable(allowedUpdateHosts),
      allowInsecureHttp: allowInsecureHttp,
      pinnedCertificatePem: pinnedCertificatePem,
      appIdOverride: appIdOverride,
      appVersionNameOverride: appVersionNameOverride,
      appBuildNumberOverride: appBuildNumberOverride,
      images: images,
    );
  }

  /// `null` for a custom server.
  final String? apiKey;
  final String serverUrl;

  /// Whether this config uses the managed server (API key + POST).
  bool get isManaged => apiKey != null;

  /// Behaviour of the "Later" button. See [LaterBehavior].
  final LaterBehavior laterBehavior;

  /// Snooze length when [laterBehavior] is [LaterBehavior.snooze].
  final Duration snoozeDuration;

  /// Show the built-in screens. Set to `false` to build everything yourself
  /// with the listener (or provide builders for just one of the two screens).
  final bool showDefaultUi;

  /// Custom full-screen blocking UI (forced updates).
  final UpdateUiBuilder? blockingBuilder;

  /// Custom sheet content (optional updates).
  final UpdateUiBuilder? sheetBuilder;

  final JUpdaterTexts texts;

  /// Header images; see [JUpdaterImages].
  final JUpdaterImages images;
  /// Verbose logging.
  final bool debug;

  /// Minimum time between automatic checks when the app returns to the foreground.
  final Duration minCheckInterval;

  final Duration requestTimeout;

  /// If not empty, `https` update URLs must be on one of these hosts (or sub-domains).
  final List<String> allowedUpdateHosts;

  /// Allow `http://` server URLs (local testing only). Custom server only.
  final bool allowInsecureHttp;

  /// PEM certificate. When set, only this certificate is trusted for the server
  /// connection (certificate pinning). Remember to ship a new app version before it expires.
  final String? pinnedCertificatePem;

  /// Override values auto-detected from the platform. Needed on Windows/Linux
  /// when `data/flutter_assets/version.json` is unavailable.
  final String? appIdOverride;
  final String? appVersionNameOverride;
  final int? appBuildNumberOverride;
}
