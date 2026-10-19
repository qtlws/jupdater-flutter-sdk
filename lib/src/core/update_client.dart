import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:jupdater/jupdater.dart';

import '../models/jupdater_config.dart';
import '../version.dart';

/// Server unreachable / timed out / HTTP error. The SDK may fall back to cache.
class UpdateNetworkException implements Exception {
  UpdateNetworkException(this.message);

  final String message;

  @override
  String toString() => 'UpdateNetworkException: $message';
}

/// TLS or certificate problem. Never falls back to cache.
class UpdateSecurityException implements Exception {
  UpdateSecurityException(this.message);

  final String message;

  @override
  String toString() => 'UpdateSecurityException: $message';
}

/// Plain `dart:io` HTTP client (no `http` package, so no dependency conflicts).
class UpdateClient {
  UpdateClient(this.config);

  final JUpdaterConfig config;

  static const int _maxResponseBytes = 64 * 1024;

  /// Returns the response body of a successful (HTTP 200) reply.
  Future<String> fetch({
    required Map<String, dynamic> payload,
    required String packageName,
    required int versionCode,
    required String platform,
    required String nonce,
  }) {
    return _fetch(
      payload: payload,
      packageName: packageName,
      versionCode: versionCode,
      platform: platform,
      nonce: nonce,
    ).timeout(
      config.requestTimeout * 2,
      onTimeout: () => throw UpdateNetworkException('Request timed out'),
    );
  }

  Future<String> _fetch({
    required Map<String, dynamic> payload,
    required String packageName,
    required int versionCode,
    required String platform,
    required String nonce,
  }) async {
    final base = Uri.parse(config.serverUrl);
    final uri = base.replace(
      queryParameters: <String, String>{
        ...base.queryParameters,
        'pid': packageName,
        'version_code': versionCode.toString(),
        'platform': platform,
        'nonce': nonce,
      },
    );
    SecurityContext? context;
    final pem = config.pinnedCertificatePem;
    if (pem != null && pem.trim().isNotEmpty) {
      context = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(utf8.encode(pem));
    }
    final client = HttpClient(context: context)
      ..connectionTimeout = config.requestTimeout
      ..idleTimeout = const Duration(seconds: 5)
      ..userAgent = '$jupdaterSdkName/$jupdaterSdkVersion';

    try {
      final request = await (config.isManaged
          ? client.postUrl(uri)
          : client.getUrl(uri));
      request.followRedirects =
          false; // never follow a redirect to another host/scheme
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      JUpdater.instance.log(
        'Request: ${config.isManaged ? 'POST' : 'GET'} $uri',
      );
      JUpdater.instance.log(
        'Request body: ${config.isManaged ? jsonEncode({...payload, 'apiKey': '[REDACTED]'}) : '(none)'}',
      );
      if (config.isManaged) {
        request.headers.set('x-api-key', config.apiKey!);
        request.headers.set(
          HttpHeaders.contentTypeHeader,
          'application/json; charset=utf-8',
        );
        final bytes = utf8.encode(jsonEncode(payload));
        request.contentLength = bytes.length;
        request.add(bytes);
      }
      final response = await request.close();
      JUpdater.instance.log('Response status: HTTP ${response.statusCode}');
      if (response.statusCode != HttpStatus.ok) {
        if (config.debug) {
          try {
            await _logErrorBody(response).timeout(const Duration(seconds: 3));
          } catch (_) {
            JUpdater.instance.log('Response body could not be fully read.');
          }
        } else {
          await response.drain<void>().timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
        }
        throw UpdateNetworkException('HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final Uint8List chunk in response.cast<Uint8List>()) {
        builder.add(chunk);
        if (builder.length > _maxResponseBytes) {
          throw const FormatException('Response too large');
        }
      }
      final body = utf8.decode(builder.takeBytes());
      JUpdater.instance.log('Response body: $body');
      return body;

    } on TlsException catch (e) {
      throw UpdateSecurityException(e.message);
    } on SocketException catch (e) {
      throw UpdateNetworkException(e.message);
    } on HttpException catch (e) {
      throw UpdateNetworkException(e.message);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _logErrorBody(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    var truncated = false;
    try {
      await for (final chunk in response) {
        final remaining = _maxResponseBytes - builder.length;
        builder.add(
          chunk.length > remaining ? chunk.sublist(0, remaining) : chunk,
        );
        if (chunk.length > remaining) {
          truncated = true;
          break;
        }
      }
    } finally {
      JUpdater.instance.log(
        'Response body: ${utf8.decode(builder.takeBytes(), allowMalformed: true)}'
        '${truncated ? ' [truncated at 64 KB]' : ''}',
      );
    }
  }
}
