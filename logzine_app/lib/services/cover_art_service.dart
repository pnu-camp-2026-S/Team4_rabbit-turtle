import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// "이번 주 나의 표지" 커버 아트 — Gemini 이미지 생성.
/// 주 1회(취향이 같으면) 생성해 로컬 캐시하고,
/// 쿼터 초과/실패 시 null을 돌려줘 호출부가 타이포그래피 표지로 폴백한다.
class CoverArtService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash-image';

  static Uint8List? _memoryCache;
  static String? _memoryKey;

  /// 이번 주 + 취향 조합의 캐시 키.
  static String _weekKey(List<String> taste) {
    final now = DateTime.now();
    final week = now.difference(DateTime(now.year)).inDays ~/ 7;
    final tasteHash = taste.take(4).join('_').hashCode.toRadixString(16);
    return '${now.year}w$week-$tasteHash';
  }

  static Future<Uint8List?> weeklyCover(List<String> taste) async {
    final key = _weekKey(taste);
    if (_memoryKey == key && _memoryCache != null) return _memoryCache;

    // 디스크 캐시 (앱 캐시 디렉토리)
    final file = File('${Directory.systemTemp.path}/logzine_cover_$key.png');
    try {
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _memoryCache = bytes;
        _memoryKey = key;
        return bytes;
      }
    } catch (_) {}

    if (_apiKey.isEmpty) return null;

    try {
      final mood = taste.isEmpty ? 'quiet editorial life' : taste.take(4).join(', ');
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
            ),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          'A minimal editorial magazine cover photograph expressing this taste: $mood. '
                          'Soft natural light, muted warm tones, film grain, elegant composition, '
                          'lots of negative space at the top. No text, no letters, no people, no watermark.',
                    },
                  ],
                },
              ],
              'generationConfig': {
                'responseModalities': ['TEXT', 'IMAGE'],
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final parts = ((decoded['candidates'] as List?)?.first['content']
          as Map<String, dynamic>?)?['parts'] as List<dynamic>?;
      if (parts == null) return null;
      for (final p in parts) {
        final inline = (p as Map<String, dynamic>)['inlineData'];
        if (inline is Map<String, dynamic>) {
          final bytes =
              Uint8List.fromList(base64Decode(inline['data'] as String));
          _memoryCache = bytes;
          _memoryKey = key;
          try {
            await file.writeAsBytes(bytes);
          } catch (_) {}
          return bytes;
        }
      }
      return null;
    } catch (_) {
      return null; // 쿼터/네트워크 — 타이포그래피 표지로 폴백
    }
  }
}
