/// Outcome of one update check. Delivered to `onUpdateCheckComplete`, to the
/// `results` stream and to custom UI builders.
class UpdateResult {
  const UpdateResult({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.isBlocked,
    required this.updateUrl,
    required this.title,
    required this.message,
    required this.latestVersionCode,
    required this.currentVersionCode,
    required this.platform,
    this.isSnoozed = false,
    this.fromCache = false,
  });

  /// `true` when the server has a newer build than the installed one.
  final bool updateAvailable;

  /// `true` when the user must update before using the app (show a blocking UI).
  /// Also `true` when the server marked the app as blocked (`is_blocked`).
  final bool forceUpdate;

  /// `true` when the server marked this app/version as blocked.
  final bool isBlocked;

  /// Store/download URL for the current platform, already validated.
  /// `null` if the server sent none or the URL failed validation.
  final String? updateUrl;

  /// Release title set by the developer on the server (max 100 characters).
  final String title;

  /// Release message set by the developer on the server (max 500 characters).
  final String message;

  final int latestVersionCode;
  final int currentVersionCode;

  /// `android`, `ios`, `macos`, `windows` or `linux`.
  final String platform;

  /// `true` when a non-forced update exists but the user already chose
  /// "Later" (dismissed this session, or snoozed). The default UI stays hidden.
  final bool isSnoozed;

  /// `true` when the result came from the offline cache (server unreachable).
  final bool fromCache;

  UpdateResult copyWith({bool? isSnoozed}) => UpdateResult(
        updateAvailable: updateAvailable,
        forceUpdate: forceUpdate,
        isBlocked: isBlocked,
        updateUrl: updateUrl,
        title: title,
        message: message,
        latestVersionCode: latestVersionCode,
        currentVersionCode: currentVersionCode,
        platform: platform,
        isSnoozed: isSnoozed ?? this.isSnoozed,
        fromCache: fromCache,
      );

  @override
  String toString() => 'UpdateResult(updateAvailable: $updateAvailable, '
      'forceUpdate: $forceUpdate, isBlocked: $isBlocked, '
      'latest: $latestVersionCode, current: $currentVersionCode, '
      'platform: $platform, isSnoozed: $isSnoozed, fromCache: $fromCache)';
}
