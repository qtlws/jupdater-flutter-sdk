import 'dart:convert';
import 'dart:io';

import 'random_ids.dart';

/// Tiny JSON-file store (installation id, offline cache, snooze). Implemented
/// with `dart:io` so the SDK needs no storage dependency.
class JStorage {
  JStorage._(this._file, this._data);

  final File _file;
  final Map<String, dynamic> _data;
  Future<void> _pending = Future<void>.value();

  static Future<JStorage> open(String directoryPath) async {
    final dir = Directory(directoryPath);
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}jupdater_state.json');
    var data = <String, dynamic>{};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      data = <String, dynamic>{};
    }
    final storage = JStorage._(file, data);
    var dirty = false;
    final id = data['installation_id'];
    if (id is! String || id.isEmpty) {
      data['installation_id'] = uuidV4();
      dirty = true;
    }
    if (data['first_seen_ms'] is! int) {
      data['first_seen_ms'] = DateTime.now().millisecondsSinceEpoch;
      dirty = true;
    }
    if (dirty) await storage._flush();
    return storage;
  }

  /// Random per-installation id (not derived from any device identifier).
  String get installationId => _data['installation_id'] as String;

  /// When the SDK first ran here. Used as `firstInstallTime` where the OS
  /// gives no install time.
  int get firstSeenMs => _data['first_seen_ms'] as int;

  Map<String, dynamic>? get cachedResponse {
    final c = _data['cached_response'];
    return c is Map ? Map<String, dynamic>.from(c) : null;
  }

  Future<void> saveCachedResponse(Map<String, dynamic> json) {
    _data['cached_response'] = json;
    return _flush();
  }

  /// End of the active snooze for [versionCode], or `null`.
  int? snoozedUntil(int versionCode) {
    final s = _data['snooze'];
    if (s is Map && s['version_code'] == versionCode && s['until_ms'] is int) {
      return s['until_ms'] as int;
    }
    return null;
  }

  Future<void> setSnooze(int versionCode, int untilMs) {
    _data['snooze'] = <String, dynamic>{
      'version_code': versionCode,
      'until_ms': untilMs,
    };
    return _flush();
  }

  Future<void> _flush() {
    _pending = _pending.then((_) async {
      final json = jsonEncode(_data);
      try {
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(json, flush: true);
        await tmp.rename(_file.path);
      } catch (_) {
        try {
          await _file.writeAsString(json, flush: true);
        } catch (_) {
          // Storage is best-effort; the SDK keeps working without it.
        }
      }
    });
    return _pending;
  }
}
