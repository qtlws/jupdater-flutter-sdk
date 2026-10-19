/// Cleans server-provided text before it is shown on a blocking screen.
///
/// Removes control characters and bidirectional-override characters (used for
/// text spoofing), normalises line endings and enforces a character limit.
/// The result is only ever rendered as plain text, never as markup.
class TextSanitizer {
  TextSanitizer._();

  static String clean(Object? value, int maxChars, {bool singleLine = false}) {
    if (value is! String) return '';
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final buf = StringBuffer();
    for (final rune in normalized.runes) {
      if (rune == 0x0A) {
        buf.write(singleLine ? ' ' : '\n');
        continue;
      }
      if (rune == 0x09) {
        buf.write(' ');
        continue;
      }
      if (rune < 0x20 || (rune >= 0x7F && rune <= 0x9F)) continue;
      if ((rune >= 0x202A && rune <= 0x202E) ||
          (rune >= 0x2066 && rune <= 0x2069) ||
          rune == 0x200E ||
          rune == 0x200F ||
          rune == 0x061C) {
        continue;
      }
      buf.writeCharCode(rune);
    }
    final trimmed = buf.toString().trim();
    final runes = trimmed.runes.toList();
    if (runes.length <= maxChars) return trimmed;
    return String.fromCharCodes(runes.take(maxChars)).trimRight();
  }
}
