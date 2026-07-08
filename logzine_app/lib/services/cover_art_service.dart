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
    // v2: 레퍼런스 기반 풀 커버 생성 규칙 (스킬: .agents/skills/logzine-cover)
    return 'v2-${now.year}w$week-$tasteHash';
  }

  /// 매거진 표지 생성 규칙 — 실제 잡지(VOGUE·Gourmet Traveller·EHOUSING)
  /// 표지 문법을 코드화한 프롬프트. 규칙 전문: .agents/skills/logzine-cover/SKILL.md
  static String _coverPrompt(List<String> taste) {
    final interests =
        taste.isEmpty ? 'quiet interiors, slow living' : taste.take(4).join(', ');
    return '''
Create a premium printed magazine FRONT COVER, portrait orientation.

RULES (follow all):
1. MASTHEAD: the single word "LOGZINE" in very large, elegant high-contrast serif capitals across the top, dark ink color. The photographic subject may slightly overlap the bottom of the letters, like classic fashion magazine covers.
2. SUBJECT: one coherent professional editorial photograph that COMBINES ALL of these reader interests into a single believable scene: $interests. Blend them naturally and playfully (example: interests "soccer, pasta" could become a stylish person twirling pasta at a table set on a football pitch; "coffee, camera" could become a warm still life of a film camera beside a pour-over coffee).
3. COVER LINE: below the masthead, one short bold English cover line of 2-4 words that captures the mood of these interests. Optional 2-3 tiny sub-lines along the left edge, very subtle.
4. STYLE: high-end editorial photography — soft natural light, warm muted tones, film grain, shallow depth of field, refined composition like Kinfolk or Gourmet Traveller.
5. All visible text must be minimal, correctly spelled English only. No barcode, no price, no watermark, no gibberish characters, no Korean text.
''';
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
                    {'text': _coverPrompt(taste)},
                  ],
                },
              ],
              'generationConfig': {
                'responseModalities': ['TEXT', 'IMAGE'],
              },
            }),
          )
          .timeout(const Duration(seconds: 45));
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
