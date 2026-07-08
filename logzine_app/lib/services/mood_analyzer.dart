import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/mood_analysis.dart';
import 'gemini_proxy_service.dart';

abstract class MoodAnalyzer {
  Future<MoodAnalysis?> analyze(List<Uint8List> photos);
}

class GeminiMoodAnalyzer implements MoodAnalyzer {
  static const String _model = 'gemini-flash-latest';

  static final String _prompt = '''
You are the taste analyzer for LOGZINE, a quiet editorial magazine app.
Look at the attached mood photos (interiors, objects, scenes the user loves)
and return ONLY a JSON object with this exact shape:

{
  "tags": [...],       // choose ONLY the 3-6 tags that BEST match, from
                       // this fixed vocabulary (be selective, not greedy):
                       // Mood: ${kMoodVocab['Mood']!.join(', ')}
                       // Space: ${kMoodVocab['Space']!.join(', ')}
                       // Style: ${kMoodVocab['Style']!.join(', ')}
  "suggested": [...],  // 4-6 short free-form keywords that capture what you
                       // actually SEE in these specific photos, in English,
                       // Title case, specific
  "summary": "..."     // one calm, editorial English sentence describing
                       // the user's taste, max 12 words
}

Only include a tag if you are confident it matches. Return valid JSON only.
''';

  @override
  Future<MoodAnalysis?> analyze(List<Uint8List> photos) async {
    if (photos.isEmpty) return null;
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

      final res = await GeminiProxyService.generateContent(
        model: _model,
        timeout: const Duration(seconds: 30),
        body: {
          'contents': [
            {'parts': parts},
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.4,
            'maxOutputTokens': 800,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );

      if (res.statusCode != 200) {
        debugPrint('MoodAnalyzer: HTTP ${res.statusCode} ${res.body}');
        return null;
      }

      final List responseParts = (jsonDecode(res.body)
          as Map<String, dynamic>)['candidates'][0]['content']['parts'] as List;
      final String text = responseParts
          .where((p) => p['thought'] != true && p['text'] != null)
          .map((p) => p['text'] as String)
          .join();
      final int start = text.indexOf('{');
      final int end = text.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final Map<String, dynamic> data =
          jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;

      final Set<String> tags = ((data['tags'] as List?) ?? const [])
          .cast<String>()
          .where(kAllMoodTags.contains)
          .toSet();
      final List<String> suggested =
          ((data['suggested'] as List?) ?? const [])
              .cast<String>()
              .take(6)
              .toList();
      final String summary = (data['summary'] as String?)?.trim() ?? '';

      if (tags.isEmpty && suggested.isEmpty) return null;
      return MoodAnalysis(tags: tags, suggested: suggested, summary: summary);
    } catch (e) {
      debugPrint('MoodAnalyzer: $e');
      return null;
    }
  }

  String _mimeOf(Uint8List bytes) =>
      bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50
          ? 'image/png'
          : 'image/jpeg';
}
