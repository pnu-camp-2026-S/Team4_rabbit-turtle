import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiProxyService {
  const GeminiProxyService._();

  static const String _proxyUrl = String.fromEnvironment('GEMINI_PROXY_URL');

  static Future<http.Response> generateContent({
    required String model,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_proxyUrl.isEmpty) {
      return http.Response(
        jsonEncode({
          'error': {
            'status': 'missing_proxy_url',
            'message': 'Run with --dart-define=GEMINI_PROXY_URL=...',
          },
        }),
        503,
        headers: const {'content-type': 'application/json'},
      );
    }

    try {
      return await http
          .post(
            Uri.parse(_proxyUrl),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'body': body,
            }),
          )
          .timeout(timeout);
    } catch (error) {
      return http.Response(
        jsonEncode({
          'error': {
            'status': 'proxy_call_failed',
            'message': error.toString(),
          },
        }),
        502,
        headers: const {'content-type': 'application/json'},
      );
    }
  }
}
