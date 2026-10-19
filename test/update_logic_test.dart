import 'package:flutter_test/flutter_test.dart';
import 'package:jupdater/src/core/random_ids.dart';
import 'package:jupdater/src/core/server_response.dart';
import 'package:jupdater/src/core/update_logic.dart';
import 'package:jupdater/src/models/update_result.dart';

ServerResponse _resp({
  int version = 10,
  bool? force,
  int gap = 0,
  bool blocked = false,
  String title = '',
  String message = '',
}) =>
    ServerResponse(
      pid: 'a.b',
      versionCode: version,
      forceUpdate: force,
      forceUpdateGap: gap,
      isBlocked: blocked,
      updateUrl: 'https://example.com/app',
      title: title,
      message: message,
    );

UpdateResult _eval(ServerResponse r, int current) => UpdateLogic.evaluate(
      response: r,
      currentVersionCode: current,
      platform: 'android',
      fromCache: false,
      fallbackTitle: 'FT',
      fallbackMessage: 'FM',
    );

void main() {
  test('no update when server is not newer', () {
    final r = _eval(_resp(version: 5), 5);
    expect(r.updateAvailable, false);
    expect(r.forceUpdate, false);
  });

  test('explicit force flag wins', () {
    expect(_eval(_resp(version: 6, force: true), 5).forceUpdate, true);
    expect(_eval(_resp(version: 60, force: false, gap: 1), 5).forceUpdate, false);
  });

  test('legacy gap rule', () {
    expect(_eval(_resp(version: 10, gap: 5), 5).forceUpdate, true);
    expect(_eval(_resp(version: 9, gap: 5), 5).forceUpdate, false);
    expect(_eval(_resp(version: 10, gap: 0), 5).forceUpdate, false);
  });

  test('blocked always forces, even without a newer build', () {
    final r = _eval(_resp(version: 5, blocked: true), 5);
    expect(r.updateAvailable, false);
    expect(r.forceUpdate, true);
    expect(r.isBlocked, true);
  });

  test('fallback texts when server sends none', () {
    final r = _eval(_resp(), 1);
    expect(r.title, 'FT');
    expect(r.message, 'FM');
    final custom = _eval(_resp(title: 'T', message: 'M'), 1);
    expect(custom.title, 'T');
    expect(custom.message, 'M');
  });

  test('uuid and hex helpers', () {
    expect(uuidV4(), matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(randomHex(16).length, 32);
    expect(formatInstallTime(0), matches(RegExp(r'^\d{4}-\d{2}-\d{2}_\d{6}[+-]\d{4}$')));
  });
}
