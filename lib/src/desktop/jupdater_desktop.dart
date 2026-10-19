/// Registration hook for Windows and Linux. These platforms are implemented in
/// pure Dart (no native code), so there is nothing to register.
class JUpdaterDesktop {
  JUpdaterDesktop._();

  /// Called by the generated plugin registrant on Windows and Linux.
  static void registerWith() {}
}
