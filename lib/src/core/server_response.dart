import 'dart:convert';

import 'text_sanitizer.dart';
import 'url_validator.dart';

/// A validated, sanitised server reply. Nothing from the network reaches the
/// rest of the SDK without passing through [ServerResponse.fromMap].
class ServerResponse {
  const ServerResponse({
    required this.pid,
    required this.versionCode,
    required this.forceUpdate,
    required this.forceUpdateGap,
    required this.isBlocked,
    required this.updateUrl,
    required this.title,
    required this.message,
  });

  static const int maxTitleChars = 100;
  static const int maxMessageChars = 500;

  /// Package/bundle id the server answered for.
  final String pid;

  /// Latest build number for the requesting platform.
  final int versionCode;

  /// Explicit force flag (`force_update`). `null` when the server did not send it.
  final bool? forceUpdate;

  /// Legacy rule: force when `latest - current >= gap` (used only if
  /// `force_update` is absent). `0` disables it.
  final int forceUpdateGap;

  final bool isBlocked;

  /// Validated update URL or `null`.
  final String? updateUrl;
  final String title;
  final String message;

  factory ServerResponse.parse(
    String body, {
    List<String> allowedHosts = const <String>[],
    String? expectedNonce,
  }) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Response is not a JSON object');
    }
    return ServerResponse.fromMap(
      Map<String, dynamic>.from(decoded),
      allowedHosts: allowedHosts,
      expectedNonce: expectedNonce,
    );
  }

  factory ServerResponse.fromMap(
    Map<String, dynamic> m, {
    List<String> allowedHosts = const <String>[],
    String? expectedNonce,
  }) {
    if (expectedNonce != null) {
      final nonce = m['nonce'];
      if (nonce != null && nonce != expectedNonce) {
        throw const FormatException('Nonce mismatch');
      }
    }
    final pid = m['pid'];
    if (pid is! String || pid.trim().isEmpty) {
      throw const FormatException('Missing or invalid "pid"');
    }
    final versionCode = _asInt(m['version_code']);
    if (versionCode == null || versionCode < 0) {
      throw const FormatException('Missing or invalid "version_code"');
    }
    final forceRaw = m['force_update'];
    final urlRaw = m['update_url'];
    return ServerResponse(
      pid: pid.trim(),
      versionCode: versionCode,
      forceUpdate: forceRaw is bool ? forceRaw : null,
      forceUpdateGap: _asInt(m['force_update_gap']) ?? 0,
      isBlocked: m['is_blocked'] == true,
      updateUrl: urlRaw is String
          ? UrlValidator.validateUpdateUrl(urlRaw, allowedHosts: allowedHosts)
          : null,
      title: TextSanitizer.clean(m['title'], maxTitleChars, singleLine: true),
      message: TextSanitizer.clean(m['message'], maxMessageChars),
    );
  }

  /// Serialisation for the offline cache (values are already validated).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'pid': pid,
        'version_code': versionCode,
        if (forceUpdate != null) 'force_update': forceUpdate,
        'force_update_gap': forceUpdateGap,
        'is_blocked': isBlocked,
        if (updateUrl != null) 'update_url': updateUrl,
        'title': title,
        'message': message,
      };

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is double && v == v.truncateToDouble()) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}
