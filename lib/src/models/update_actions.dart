/// Actions handed to custom UI builders so a developer's own widgets can drive
/// the update flow.
class UpdateActions {
  const UpdateActions({
    required this.update,
    required this.later,
    required this.closeApp,
    required this.canCloseApp,
    required this.hasUpdateUrl,
  });

  /// Opens the store/download URL. Completes with `false` if it could not be opened.
  final Future<bool> Function() update;

  /// "Later": applies the configured [LaterBehavior] (dismiss or snooze) and
  /// hides the sheet. Does nothing for a forced update.
  final void Function() later;

  /// Closes the app where the platform allows it.
  final void Function() closeApp;

  /// `false` on iOS, where apps must not terminate themselves.
  final bool canCloseApp;

  /// `false` when there is no valid update URL (disable your Update button).
  final bool hasUpdateUrl;
}
