import 'package:flutter_test/flutter_test.dart';
import 'package:jupdater/src/core/url_validator.dart';

void main() {
  group('validateUpdateUrl', () {
    test('accepts store URLs', () {
      expect(
        UrlValidator.validateUpdateUrl('https://play.google.com/store/apps/details?id=a.b'),
        isNotNull,
      );
      expect(UrlValidator.validateUpdateUrl('market://details?id=a.b'), isNotNull);
      expect(UrlValidator.validateUpdateUrl('itms-apps://apps.apple.com/app/id1'), isNotNull);
      expect(UrlValidator.validateUpdateUrl('ms-windows-store://pdp/?productid=9ABC'), isNotNull);
    });

    test('rejects dangerous or malformed URLs', () {
      expect(UrlValidator.validateUpdateUrl('javascript:alert(1)'), isNull);
      expect(UrlValidator.validateUpdateUrl('file:///etc/passwd'), isNull);
      expect(UrlValidator.validateUpdateUrl('http://example.com/app'), isNull);
      expect(UrlValidator.validateUpdateUrl('intent://x#Intent;end'), isNull);
      expect(UrlValidator.validateUpdateUrl('https://user:pw@example.com/'), isNull);
      expect(UrlValidator.validateUpdateUrl('https://exa mple.com'), isNull);
      expect(UrlValidator.validateUpdateUrl(''), isNull);
      expect(UrlValidator.validateUpdateUrl(null), isNull);
    });

    test('host allow-list', () {
      const hosts = <String>['apps.apple.com'];
      expect(UrlValidator.validateUpdateUrl('https://apps.apple.com/app/id1', allowedHosts: hosts), isNotNull);
      expect(UrlValidator.validateUpdateUrl('https://evil.example/app', allowedHosts: hosts), isNull);
      expect(UrlValidator.validateUpdateUrl('https://apps.apple.com.evil.example/', allowedHosts: hosts), isNull);
    });
  });

  group('validateServerUrl', () {
    test('requires https unless explicitly allowed', () {
      expect(() => UrlValidator.validateServerUrl('http://x.com/a'), throwsArgumentError);
      expect(UrlValidator.validateServerUrl('https://x.com/a'), 'https://x.com/a');
      expect(
        UrlValidator.validateServerUrl('http://10.0.2.2:3000/a', allowInsecureHttp: true),
        isNotEmpty,
      );
    });

    test('rejects empty and credentials', () {
      expect(() => UrlValidator.validateServerUrl(' '), throwsArgumentError);
      expect(() => UrlValidator.validateServerUrl('https://u:p@x.com/'), throwsArgumentError);
    });
  });
}
