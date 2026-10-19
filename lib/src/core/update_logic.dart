import '../models/update_result.dart';
import 'server_response.dart';

/// Pure decision logic (no I/O) so it can be unit-tested.
class UpdateLogic {
  UpdateLogic._();

  static UpdateResult evaluate({
    required ServerResponse response,
    required int currentVersionCode,
    required String platform,
    required bool fromCache,
    required String fallbackTitle,
    required String fallbackMessage,
  }) {
    final updateAvailable = response.versionCode > currentVersionCode;

    var force = false;
    if (updateAvailable) {
      final explicit = response.forceUpdate;
      if (explicit != null) {
        force = explicit;
      } else if (response.forceUpdateGap > 0) {
        force = response.versionCode - currentVersionCode >=
            response.forceUpdateGap;
      }
    }
    // A blocked app always gets the blocking screen, even when no newer build exists.
    if (response.isBlocked) force = true;

    return UpdateResult(
      updateAvailable: updateAvailable,
      forceUpdate: force,
      isBlocked: response.isBlocked,
      updateUrl: response.updateUrl,
      title: response.title.isEmpty ? fallbackTitle : response.title,
      message: response.message.isEmpty ? fallbackMessage : response.message,
      latestVersionCode: response.versionCode,
      currentVersionCode: currentVersionCode,
      platform: platform,
      fromCache: fromCache,
    );
  }
}
