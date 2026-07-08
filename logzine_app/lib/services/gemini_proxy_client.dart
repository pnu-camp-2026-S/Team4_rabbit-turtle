import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiProxyClient {
  const GeminiProxyClient._();

  static const String proxyUrl = String.fromEnvironment('GEMINI_PROXY_URL');

  static bool get isConfigured => proxyUrl.trim().isNotEmpty;

  static Future<http.Response> generateContent({
    required String model,
    required Map<String, dynamic> body,
    required Duration timeout,
  }) async {
    if (!isConfigured) {
      throw const GeminiProxyException(
        'GEMINI_PROXY_URL이 없습니다. env.json에 Worker URL을 설정해주세요.',
      );
    }

    final path = 'v1beta/models/$model:generateContent';
    final response = await _post(_withPath(path), body).timeout(timeout);
    if (response.statusCode != 404 && response.statusCode != 405) {
      return response;
    }

    return _post(Uri.parse(proxyUrl), {
      'model': model,
      'path': path,
      ...body,
    }).timeout(timeout);
  }

  static Future<http.Response> _post(Uri uri, Map<String, dynamic> body) {
    return http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Uri _withPath(String path) {
    final trimmedBase = proxyUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final trimmedPath = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$trimmedBase/$trimmedPath');
  }
}

class GeminiProxyException implements Exception {
  const GeminiProxyException(this.message);

  final String message;

  @override
  String toString() => message;
}
