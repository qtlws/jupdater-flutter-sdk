import 'dart:io';

import 'package:flutter/services.dart';

/// Thin wrapper around the platform channel (Android, iOS, macOS) plus
/// pure-Dart fallbacks for Windows and Linux.
class NativeBridge {
  NativeBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.qtlws.jupdater/native');

  static Future<Map<String, dynamic>> getPlatformInfo() async {
    final res =
        await _channel.invokeMapMethod<String, dynamic>('getPlatformInfo');
    return res ?? const <String, dynamic>{};
  }

  /// Opens an already-validated update URL with the OS handler.
  static Future<bool> openUrl(String url, String platform) async {
    try {
      switch (platform) {
        case 'android':
        case 'ios':
        case 'macos':
          final ok = await _channel
              .invokeMethod<bool>('openUrl', <String, dynamic>{'url': url});
          return ok ?? false;
        case 'windows':
          // rundll32 does not go through a shell, so '&' etc. in the URL is harmless.
          await Process.start(
            'rundll32',
            <String>['url.dll,FileProtocolHandler', url],
            mode: ProcessStartMode.detached,
          );
          return true;
        case 'linux':
          await Process.start(
            'xdg-open',
            <String>[url],
            mode: ProcessStartMode.detached,
          );
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
