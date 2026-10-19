import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';

import '../models/jupdater_config.dart';
import 'native_bridge.dart';

/// Everything the SDK needs to know about the app and device.
class JPlatformInfo {
  const JPlatformInfo({
    required this.platform,
    required this.packageName,
    required this.versionName,
    required this.buildNumber,
    required this.supportDir,
    required this.brand,
    required this.device,
    required this.model,
    required this.manufacturer,
    required this.board,
    required this.osVersion,
    required this.country,
    required this.firstInstallTimeMs,
  });

  /// `android`, `ios`, `macos`, `windows` or `linux`.
  final String platform;
  final String packageName;
  final String versionName;
  final int buildNumber;
  final String supportDir;
  final String brand;
  final String device;
  final String model;
  final String manufacturer;
  final String board;
  final String osVersion;
  final String country;

  /// `0` when the OS does not provide it.
  final int firstInstallTimeMs;
}

class PlatformInfoLoader {
  PlatformInfoLoader._();

  /// Platform name sent to the server, or `null` for unsupported platforms.
  static String? currentPlatform() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static Future<JPlatformInfo?> load(JUpdaterConfig config) async {
    final platform = currentPlatform();
    if (platform == null) return null;

    final isDesktopDart = platform == 'windows' || platform == 'linux';
    final Map<String, dynamic> n =
        isDesktopDart ? await _desktopInfo(platform) : await NativeBridge.getPlatformInfo();

    final packageName =
        config.appIdOverride ?? (n['packageName'] as String? ?? '');
    final versionName =
        config.appVersionNameOverride ?? (n['versionName'] as String? ?? '');
    final buildNumber =
        config.appBuildNumberOverride ?? _parseBuild(n['buildNumber']);

    var supportDir = n['supportDir'] as String? ?? '';
    if (isDesktopDart) {
      supportDir = _desktopSupportDir(platform, packageName);
    }

    return JPlatformInfo(
      platform: platform,
      packageName: packageName,
      versionName: versionName,
      buildNumber: buildNumber,
      supportDir: supportDir,
      brand: n['brand'] as String? ?? '',
      device: n['device'] as String? ?? '',
      model: n['model'] as String? ?? '',
      manufacturer: n['manufacturer'] as String? ?? '',
      board: n['board'] as String? ?? '',
      osVersion: n['osVersion'] as String? ?? '',
      country: PlatformDispatcher.instance.locale.countryCode ?? '',
      firstInstallTimeMs: _asInt(n['firstInstallTime']) ?? 0,
    );
  }

  static int _parseBuild(Object? v) {
    if (v is int) return v;
    if (v is String) {
      final direct = int.tryParse(v.trim());
      if (direct != null) return direct;
      final m = RegExp(r'\d+').firstMatch(v);
      if (m != null) return int.parse(m.group(0)!);
    }
    return 0;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  // ---- Windows / Linux (pure Dart) ----

  static Future<Map<String, dynamic>> _desktopInfo(String platform) async {
    final v = await _readVersionJson();
    return <String, dynamic>{
      'packageName': (v['package_name'] ?? '').toString(),
      'versionName': (v['version'] ?? '').toString(),
      'buildNumber': (v['build_number'] ?? '').toString(),
      'brand': platform == 'windows' ? 'Microsoft' : 'Linux',
      'device': 'desktop',
      'model': 'desktop',
      'manufacturer': '',
      'board': '',
      'osVersion': Platform.operatingSystemVersion,
      'firstInstallTime': 0,
    };
  }

  /// Flutter desktop builds ship `data/flutter_assets/version.json` next to the executable.
  static Future<Map<String, dynamic>> _readVersionJson() async {
    try {
      final sep = Platform.pathSeparator;
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final f = File(
          '$exeDir${sep}data${sep}flutter_assets${sep}version.json');
      if (await f.exists()) {
        final decoded = jsonDecode(await f.readAsString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  static String _desktopSupportDir(String platform, String packageName) {
    final sep = Platform.pathSeparator;
    final env = Platform.environment;
    final String base;
    if (platform == 'windows') {
      base = env['APPDATA'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
    } else {
      final xdg = env['XDG_DATA_HOME'];
      final home = env['HOME'];
      base = (xdg != null && xdg.isNotEmpty)
          ? xdg
          : (home != null && home.isNotEmpty)
              ? '$home/.local/share'
              : Directory.systemTemp.path;
    }
    var safe = packageName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (safe.isEmpty) safe = 'app';
    return '$base$sep$safe${sep}jupdater';
  }
}
