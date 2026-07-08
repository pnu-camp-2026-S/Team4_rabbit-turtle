import 'dart:convert';

import 'gemini_proxy_client.dart';

/// AI 큐레이터 — 사용자 취향과 오늘의 픽으로 홈 상단의 에디터 한 줄을 만든다.
/// Gemini 실패/프록시 없음/비로그인 시 로컬 템플릿 폴백 (앱은 항상 동작).
class CuratorService {
  static const String _model = 'gemini-flash-latest';

  /// 같은 날 + 같은 취향 + 같은 픽이면 재호출하지 않는다 (세션 캐시).
  static String? _cachedLine;
  static String? _cacheKey;

  static Future<String> todayLine({
    required List<String> taste,
    required String topPick,
  }) async {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month}-${now.day}'
        '|${taste.join(',')}|$topPick';
    if (_cacheKey == key && _cachedLine != null) return _cachedLine!;

    final String fallback = _fallbackLine(taste: taste, topPick: topPick);
    if (!GeminiProxyClient.isConfigured || topPick.isEmpty) return fallback;

    try {
      final response = await GeminiProxyClient.generateContent(
        model: _model,
        timeout: const Duration(seconds: 8),
        body: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': _prompt(taste: taste, topPick: topPick, now: now)},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.85,
            'maxOutputTokens': 120,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      final parts =
          ((candidates?.first as Map<String, dynamic>?)?['content']
                  as Map<String, dynamic>?)?['parts']
              as List<dynamic>?;
      final text = parts
          ?.map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join()
          .trim()
          .replaceAll(RegExp(r'^["“‘]+|["”’.!]+$'), '')
          .trim();

      if (text == null || text.isEmpty || text.length > 70) return fallback;
      _cacheKey = key;
      _cachedLine = text;
      return text;
    } catch (_) {
      return fallback;
    }
  }

  static String _prompt({
    required List<String> taste,
    required String topPick,
    required DateTime now,
  }) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final day = weekdays[now.weekday - 1];
    final tags = taste.isEmpty ? '아직 없음' : taste.take(4).join(', ');
    return '당신은 감각적인 매거진 에디터입니다. '
        '오늘의 큐레이션 인사말을 딱 한 문장, 한국어 45자 이내로 쓰세요. '
        '따옴표·이모지·느낌표 없이 차분한 에디토리얼 톤. '
        '독자의 취향 태그($tags)와 오늘($day요일)의 분위기를 자연스럽게 녹이고, '
        '추천 매거진 "$topPick"으로 시선을 이끄세요. 문장만 출력.';
  }

  static String _fallbackLine({
    required List<String> taste,
    required String topPick,
  }) {
    if (topPick.isEmpty) return 'Picked from your taste';
    if (taste.isEmpty) return '오늘의 가판대, $topPick부터 천천히.';
    return "'${taste.first}' 취향이라면, 오늘은 $topPick부터 펼쳐보세요.";
  }
}
