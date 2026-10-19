import 'dart:math';

/// RFC 4122 version 4 UUID from a cryptographically secure generator.
String uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

/// Random lowercase hex string made of [bytes] random bytes.
String randomHex(int bytes) {
  final r = Random.secure();
  final sb = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    sb.write(r.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// `yyyy-MM-dd_HHmmss+0530` (same format the Android SDK sent as `firstInstallTime`).
String formatInstallTime(int millisSinceEpoch) {
  final d = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
  String two(int n) => n.toString().padLeft(2, '0');
  final off = d.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final abs = off.abs();
  final y = d.year.toString().padLeft(4, '0');
  return '$y-${two(d.month)}-${two(d.day)}_'
      '${two(d.hour)}${two(d.minute)}${two(d.second)}'
      '$sign${two(abs.inHours)}${two(abs.inMinutes.remainder(60))}';
}
