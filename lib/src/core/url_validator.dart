/// Validation for the server URL (developer-supplied) and for update URLs
/// (server-supplied, therefore untrusted).
class UrlValidator {
  UrlValidator._();

  /// Schemes an update URL may use. Everything else (javascript:, file:, data:,
  /// intent:, custom app schemes ...) is rejected.
  static const Set<String> allowedUpdateSchemes = <String>{
    'https',
    'market', // Google Play
    'itms-apps', // App Store (iOS)
    'itms-appss',
    'macappstore', // Mac App Store
    'macappstores',
    'ms-windows-store', // Microsoft Store
    'snap', // Snap Store
    'appstream', // Linux software centers
  };

  static const int _maxUrlLength = 2048;

  /// Returns the normalised update URL, or `null` if it must not be used.
  ///
  /// [allowedHosts] (optional) restricts `https` URLs to these hosts or their
  /// sub-domains.
  static String? validateUpdateUrl(
    String? raw, {
    List<String> allowedHosts = const <String>[],
  }) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value.length > _maxUrlLength) return null;
    if (RegExp(r'[\s\u0000-\u001F\u007F]').hasMatch(value)) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (!allowedUpdateSchemes.contains(scheme)) return null;

    if (scheme == 'https') {
      if (uri.host.isEmpty) return null;
      if (uri.userInfo.isNotEmpty) return null;
      if (allowedHosts.isNotEmpty) {
        final host = uri.host.toLowerCase();
        final ok = allowedHosts.any((h) {
          final allowed = h.trim().toLowerCase();
          return allowed.isNotEmpty &&
              (host == allowed || host.endsWith('.$allowed'));
        });
        if (!ok) return null;
      }
    }
    return uri.toString();
  }

  /// Validates the developer-supplied server URL. Throws [ArgumentError].
  static String validateServerUrl(
    String raw, {
    bool allowInsecureHttp = false,
  }) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(raw, 'serverUrl', 'must not be empty');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      throw ArgumentError.value(raw, 'serverUrl', 'is not a valid URL');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && !(allowInsecureHttp && scheme == 'http')) {
      throw ArgumentError.value(
        raw,
        'serverUrl',
        'must use https (set allowInsecureHttp only for local testing)',
      );
    }
    if (uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
          raw, 'serverUrl', 'must not contain credentials');
    }
    return uri.toString();
  }
}
