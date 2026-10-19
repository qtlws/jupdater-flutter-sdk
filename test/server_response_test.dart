import 'package:flutter_test/flutter_test.dart';
import 'package:jupdater/src/core/server_response.dart';
import 'package:jupdater/src/core/text_sanitizer.dart';

void main() {
  const base =
      '{"pid":"com.acme.app","version_code":12,"update_url":"https://apps.apple.com/app/id1",'
      '"force_update":true,"is_blocked":false,"title":"New release","message":"Lots of fixes"}';

  test('parses a valid response', () {
    final r = ServerResponse.parse(base);
    expect(r.pid, 'com.acme.app');
    expect(r.versionCode, 12);
    expect(r.forceUpdate, true);
    expect(r.updateUrl, 'https://apps.apple.com/app/id1');
    expect(r.title, 'New release');
  });

  test('accepts numeric strings and legacy force_update_gap', () {
    final r = ServerResponse.parse(
        '{"pid":"a.b","version_code":"7","force_update_gap":3}');
    expect(r.versionCode, 7);
    expect(r.forceUpdate, isNull);
    expect(r.forceUpdateGap, 3);
  });

  test('rejects missing pid / version_code / non-object', () {
    expect(() => ServerResponse.parse('{"version_code":1}'), throwsFormatException);
    expect(() => ServerResponse.parse('{"pid":"a"}'), throwsFormatException);
    expect(() => ServerResponse.parse('[1,2]'), throwsFormatException);
    expect(() => ServerResponse.parse('not json'), throwsFormatException);
  });

  test('drops an unsafe update url but keeps the response', () {
    final r = ServerResponse.parse(
        '{"pid":"a.b","version_code":2,"update_url":"javascript:alert(1)"}');
    expect(r.updateUrl, isNull);
  });

  test('nonce must match when the server echoes one', () {
    expect(
      () => ServerResponse.parse('{"pid":"a","version_code":1,"nonce":"x"}',
          expectedNonce: 'y'),
      throwsFormatException,
    );
    expect(
      ServerResponse.parse('{"pid":"a","version_code":1,"nonce":"y"}',
          expectedNonce: 'y').pid,
      'a',
    );
    // Server that does not echo a nonce is still accepted.
    expect(
      ServerResponse.parse('{"pid":"a","version_code":1}', expectedNonce: 'y').pid,
      'a',
    );
  });

  test('enforces title (100) and message (500) limits', () {
    final long = 'x' * 900;
    final r = ServerResponse.parse(
        '{"pid":"a","version_code":1,"title":"$long","message":"$long"}');
    expect(r.title.length, ServerResponse.maxTitleChars);
    expect(r.message.length, ServerResponse.maxMessageChars);
  });

  test('cache round-trip keeps validated values', () {
    final r = ServerResponse.parse(base);
    final again = ServerResponse.fromMap(r.toJson());
    expect(again.pid, r.pid);
    expect(again.updateUrl, r.updateUrl);
    expect(again.forceUpdate, r.forceUpdate);
  });

  group('TextSanitizer', () {
    test('removes control and bidi override characters', () {
      expect(TextSanitizer.clean('a\u0000b\u202Ec', 50), 'abc');
    });
    test('single line mode', () {
      expect(TextSanitizer.clean('a\nb', 50, singleLine: true), 'a b');
    });
    test('non strings give empty text', () {
      expect(TextSanitizer.clean(42, 50), '');
    });
    test('does not split surrogate pairs', () {
      final s = '😀' * 10;
      expect(TextSanitizer.clean(s, 3).runes.length, 3);
    });
  });
}
