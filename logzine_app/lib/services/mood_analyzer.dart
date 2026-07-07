import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/mood_analysis.dart';

/// 사진 → 무드 분석 추상화.
/// 구현체를 교체하면 다른 AI 공급자(CLOVA 등)로 갈아끼울 수 있다.
abstract class MoodAnalyzer {
  /// 분석 실패·API 키 없음이면 null (호출부는 데모 태그로 폴백).
  Future<MoodAnalysis?> analyze(List<Uint8List> photos);
}

/// Google Gemini Flash 기반 구현.
///
/// 활성화: `flutter run --dart-define=GEMINI_API_KEY=발급키`
/// (키는 절대 커밋하지 않는다 — 없으면 자동으로 데모 모드)
class GeminiMoodAnalyzer implements MoodAnalyzer {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.0-flash';

  static final String _prompt = '''
You are the taste analyzer for LOGZINE, a quiet editorial magazine app.
Look at the attached mood photos (interiors, objects, scenes the user loves)
and return ONLY a JSON object with this exact shape:

{
  "tags": [...],       // pick every fitting tag from this fixed vocabulary:
                       // Mood: ${kMoodVocab['Mood']!.join(', ')}
                       // Space: ${kMoodVocab['Space']!.join(', ')}
                       // Style: ${kMoodVocab['Style']!.join(', ')}
  "suggested": [...],  // up to 3 short free-form taste keywords in English,
                       // Title case, e.g. "Warm wood", "Soft light"
  "summary": "..."     // one calm, editorial English sentence describing
                       // the user's taste, max 12 words
}

Use only tags that genuinely match the photos. Return valid JSON only.
''';

  @override
  Future<MoodAnalysis?> analyze(List<Uint8List> photos) async {
    if (_apiKey.isEmpty || photos.isEmpty) return null;
    try {
      final List<Map<String, dynamic>> parts = [
        {'text': _prompt},
        for (final bytes in photos.take(4))
          {
            'inline_data': {
              'mime_type': _mimeOf(bytes),
              'data': base64Encode(bytes),
            },
          },
      ];

      final http.Response res = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              '$_model:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {'parts': parts},
              ],
              'generationConfig': {
                'response_mime_type': 'application/json',
                'temperature': 0.4,
              },
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        debugPrint('MoodAnalyzer: HTTP ${res.statusCode} ${res.body}');
        return null;
      }

      final String text = (jsonDecode(res.body) as Map<String, dynamic>)
          ['candidates'][0]['content']['parts'][0]['text'] as String;
      final Map<String, dynamic> data =
          jsonDecode(text) as Map<String, dynamic>;

      final Set<String> tags = ((data['tags'] as List?) ?? const [])
          .cast<String>()
          .where(kAllMoodTags.contains)
          .toSet();
      final List<String> suggested =
          ((data['suggested'] as List?) ?? const [])
              .cast<String>()
              .take(3)
              .toList();
      final String summary = (data['summary'] as String?)?.trim() ?? '';

      if (tags.isEmpty && suggested.isEmpty) return null;
      return MoodAnalysis(tags: tags, suggested: suggested, summary: summary);
    } catch (e) {
      debugPrint('MoodAnalyzer: $e');
      return null; // 어떤 실패든 데모 태그로 폴백
    }
  }

  /// PNG 매직 넘버로 간단히 판별, 그 외에는 JPEG로 취급.
  String _mimeOf(Uint8List bytes) =>
      bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50
          ? 'image/png'
          : 'image/jpeg';
}
