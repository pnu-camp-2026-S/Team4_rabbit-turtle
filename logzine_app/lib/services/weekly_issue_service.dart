import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/article.dart';
import 'cover_art_service.dart';
import 'gemini_proxy_service.dart';
import 'magazine_service.dart';
import 'mark_service.dart';
import 'reading_stats_service.dart';
import 'saved_service.dart';
import 'user_service.dart';

/// 주간 이슈 목차 한 줄 — 이번 주 저장한 아티클.
class WeeklyIssueEntry {
  const WeeklyIssueEntry({
    required this.articleId,
    required this.magazineId,
    required this.articleTitle,
    required this.magazineTitle,
    required this.coverUrl,
  });

  final String articleId;
  final String magazineId;
  final String articleTitle;
  final String magazineTitle;
  final String coverUrl;
}

/// 주간 이슈에 실리는 밑줄 문장.
class WeeklyQuote {
  const WeeklyQuote({required this.text, required this.source});

  final String text;
  final String source;
}

/// "LOGZINE Weekly — 나의 주간 이슈" 한 호의 재료 전부.
/// 기존 기능(MY COVER·저장·마크·읽기 통계·큐레이터)의 데이터를 조립만 한다.
class WeeklyIssueData {
  const WeeklyIssueData({
    required this.weekStart,
    required this.weekEnd,
    required this.issueNumber,
    required this.tasteTags,
    required this.coverArt,
    required this.entries,
    required this.entriesAreRecentFallback,
    required this.quotes,
    required this.weekSeconds,
    required this.marksThisWeek,
    required this.bestDayLabel,
    required this.dailySeconds,
    required this.editorNote,
  });

  final DateTime weekStart; // 월요일
  final DateTime weekEnd; // 일요일
  final int issueNumber; // 올해 몇 번째 주
  final List<String> tasteTags;

  /// MY COVER와 동일한 Gemini 생성 표지 (실패 시 null → 타이포 표지).
  final Uint8List? coverArt;

  /// 목차 — 이번 주 저장한 아티클. 이번 주가 비면 최근 저장으로 폴백.
  final List<WeeklyIssueEntry> entries;
  final bool entriesAreRecentFallback;

  /// 이번 주 밑줄 친 문장들 (최대 3개).
  final List<WeeklyQuote> quotes;

  final int weekSeconds;
  final int marksThisWeek;
  final String bestDayLabel; // 가장 오래 읽은 요일 (예: '수요일'), 없으면 ''

  /// 월~일 7칸 읽기 시간(초) — 뒷표지 미니 그래프용. 통계 실패 시 빈 리스트.
  final List<int> dailySeconds;

  /// 에디터의 말 — Gemini 한 문단, 실패 시 로컬 템플릿.
  final String editorNote;
}

/// 주간 이슈 컴포저. 각 재료는 개별 실패해도 나머지로 호는 발행된다.
class WeeklyIssueService {
  static const String _model = 'gemini-flash-latest';

  /// 같은 주 + 같은 재료면 재조립하지 않는다 (세션 캐시 — 커버 재생성 방지는
  /// CoverArtService가 자체 캐시로 이미 보장하므로 여기선 에디터의 말이 대상).
  static WeeklyIssueData? _cache;
  static String? _cacheKey;

  static const List<String> _weekdayLabels = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일',
  ];

  static Future<WeeklyIssueData> compose() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final int issueNumber = now.difference(DateTime(now.year)).inDays ~/ 7 + 1;

    List<String> taste = const [];
    try {
      taste = await UserService().fetchTasteTags() ?? const [];
    } catch (_) {}

    // 목차 — 이번 주 저장분, 없으면 최근 저장 폴백
    List<WeeklyIssueEntry> entries = const [];
    bool entriesAreRecentFallback = false;
    try {
      final docs = await SavedService().fetchSaved(limit: 20);
      final all = <WeeklyIssueEntry>[];
      final thisWeek = <WeeklyIssueEntry>[];
      for (final doc in docs) {
        final data = doc.data();
        final entry = WeeklyIssueEntry(
          articleId: doc.id,
          magazineId: data['magazineId'] as String? ?? '',
          articleTitle: data['articleTitle'] as String? ?? '(제목 없음)',
          magazineTitle: data['magazineTitle'] as String? ?? 'LOGZINE',
          coverUrl: data['coverUrl'] as String? ?? '',
        );
        all.add(entry);
        final rawSavedAt = data['savedAt'];
        if (rawSavedAt is Timestamp &&
            !rawSavedAt.toDate().isBefore(weekStart)) {
          thisWeek.add(entry);
        }
      }
      if (thisWeek.isNotEmpty) {
        entries = thisWeek.take(5).toList();
      } else {
        entries = all.take(3).toList();
        entriesAreRecentFallback = entries.isNotEmpty;
      }
    } catch (_) {}

    // 이번 주 밑줄 문장 — archive와 동일하게 좌표를 본문 문장으로 해석
    List<WeeklyQuote> quotes = const [];
    int marksThisWeek = 0;
    try {
      final records = await MarkService().fetchRecentMarks(limit: 30);
      final inWeek = [
        for (final record in records)
          if (record.createdAt != null &&
              !record.createdAt!.isBefore(weekStart))
            record,
      ];
      marksThisWeek = inWeek.length;
      quotes = await _resolveQuotes(inWeek.take(6).toList());
    } catch (_) {}

    // 읽기 통계 — 주간 합계 + 가장 오래 읽은 요일
    int weekSeconds = 0;
    String bestDayLabel = '';
    List<ReadingStatRecord> weekly = const [];
    try {
      weekly = await ReadingStatsService().fetchWeeklyStats();
      int bestIdx = -1;
      int bestSeconds = 0;
      for (var i = 0; i < weekly.length; i++) {
        weekSeconds += weekly[i].secondsRead;
        if (weekly[i].secondsRead > bestSeconds) {
          bestSeconds = weekly[i].secondsRead;
          bestIdx = i;
        }
      }
      if (bestIdx >= 0) bestDayLabel = _weekdayLabels[bestIdx];
    } catch (_) {}

    // 세션 캐시 — 표지 생성/에디터의 말 재호출 방지
    final String key =
        '$issueNumber|${taste.join(',')}|${entries.length}|$marksThisWeek|'
        '${weekSeconds ~/ 60}';
    if (_cacheKey == key && _cache != null) return _cache!;

    Uint8List? coverArt;
    try {
      coverArt = await CoverArtService.weeklyCover(taste);
    } catch (_) {}

    final String editorNote = await _editorNote(
      taste: taste,
      entryTitles: [for (final e in entries) e.articleTitle],
      quoteCount: marksThisWeek,
      readMinutes: weekSeconds ~/ 60,
    );

    final data = WeeklyIssueData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      issueNumber: issueNumber,
      tasteTags: taste,
      coverArt: coverArt,
      entries: entries,
      entriesAreRecentFallback: entriesAreRecentFallback,
      quotes: quotes,
      weekSeconds: weekSeconds,
      marksThisWeek: marksThisWeek,
      bestDayLabel: bestDayLabel,
      dailySeconds: [for (final record in weekly) record.secondsRead],
      editorNote: editorNote,
    );
    _cache = data;
    _cacheKey = key;
    return data;
  }

  /// 마크 좌표 → 본문 문장. 같은 아티클은 한 번만 조회 (archive와 동일 정책).
  static Future<List<WeeklyQuote>> _resolveQuotes(
    List<MarkRecord> records,
  ) async {
    final Map<String, Article?> cache = {};
    final List<WeeklyQuote> quotes = [];
    for (final record in records) {
      if (quotes.length >= 3) break;
      final String key = '${record.magazineId}/${record.articleId}';
      Article? article;
      if (cache.containsKey(key)) {
        article = cache[key];
      } else {
        try {
          article = await MagazineService().fetchArticleById(
            magazineId: record.magazineId,
            articleId: record.articleId,
          );
        } catch (_) {
          article = null;
        }
        cache[key] = article;
      }
      if (article == null) continue;
      if (record.paragraphIdx < 0 ||
          record.paragraphIdx >= article.paragraphs.length) {
        continue;
      }
      final segments = article.paragraphs[record.paragraphIdx];
      if (record.segmentIdx < 0 || record.segmentIdx >= segments.length) {
        continue;
      }
      quotes.add(
        WeeklyQuote(
          text: segments[record.segmentIdx],
          source: article.title.isNotEmpty ? article.title : 'LOGZINE',
        ),
      );
    }
    return quotes;
  }

  /// 에디터의 말 — Gemini 한 문단 (한국어), 실패 시 로컬 템플릿 폴백.
  static Future<String> _editorNote({
    required List<String> taste,
    required List<String> entryTitles,
    required int quoteCount,
    required int readMinutes,
  }) async {
    final String fallback = _fallbackNote(
      taste: taste,
      savedCount: entryTitles.length,
      quoteCount: quoteCount,
      readMinutes: readMinutes,
    );
    try {
      final response = await GeminiProxyService.generateContent(
        model: _model,
        timeout: const Duration(seconds: 10),
        body: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      '당신은 매거진 LOGZINE의 에디터입니다. 독자의 주간 이슈에 실릴 '
                      '"에디터의 말"을 한국어 2~3문장, 140자 이내로 쓰세요. '
                      '따옴표·이모지·느낌표 없이 차분하고 다정한 에디토리얼 톤(해요체). '
                      '반드시 한국어로만 쓰세요.\n'
                      '독자의 이번 주: 취향 태그(${taste.take(4).join(', ')}), '
                      '저장한 아티클(${entryTitles.take(3).join(', ')}), '
                      '밑줄 $quoteCount개, 읽은 시간 $readMinutes분. '
                      '이 활동에서 읽히는 취향의 결을 짚어주세요. 문장만 출력.',
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 300,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final parts =
          ((decoded['candidates'] as List?)?.first['content']
                  as Map<String, dynamic>?)?['parts']
              as List<dynamic>?;
      final text = parts
          ?.map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join()
          .trim();
      if (text == null || text.isEmpty || text.length > 220) return fallback;
      return text;
    } catch (_) {
      return fallback;
    }
  }

  static String _fallbackNote({
    required List<String> taste,
    required int savedCount,
    required int quoteCount,
    required int readMinutes,
  }) {
    final String tag = taste.isEmpty ? '조용한 취향' : taste.first;
    if (savedCount == 0 && quoteCount == 0) {
      return '이번 주는 천천히 흘러갔어요. 다음 주에는 \'$tag\' 결의 페이지들이 '
          '당신을 기다리고 있을 거예요.';
    }
    return '이번 주 당신은 $savedCount편을 저장하고 $quoteCount개의 문장에 '
        '밑줄을 그었어요. \'$tag\'을(를) 향한 시선이 한 뼘 더 깊어진 한 주였어요.';
  }
}
