import '../models/update_result.dart';

enum UpdateUiKind { none, sheet, blocking }

/// What the overlay layer should currently show.
class UpdateUiState {
  const UpdateUiState._(this.kind, this.result);

  static const UpdateUiState none = UpdateUiState._(UpdateUiKind.none, null);

  factory UpdateUiState.sheet(UpdateResult result) =>
      UpdateUiState._(UpdateUiKind.sheet, result);

  factory UpdateUiState.blocking(UpdateResult result) =>
      UpdateUiState._(UpdateUiKind.blocking, result);

  final UpdateUiKind kind;
  final UpdateResult? result;

  bool sameAs(UpdateUiState other) {
    if (kind != other.kind) return false;
    final a = result;
    final b = other.result;
    if (a == null || b == null) return a == b;
    return a.latestVersionCode == b.latestVersionCode &&
        a.updateUrl == b.updateUrl &&
        a.title == b.title &&
        a.message == b.message &&
        a.forceUpdate == b.forceUpdate;
  }
}
