import '../models/magazine.dart';
import '../models/ui_keyword_vocabulary.dart';

/// 취향 태그 ∩ 매거진 태그 기반 추천 로직.
/// Firestore 의존이 없는 순수 함수 — 단위 테스트로 검증한다.
///
/// 어휘 브리지: 과거 저장값도 UI keyword vocabulary 안의 태그로만 정규화한다.
class RecommendationService {
  static final List<String> kPickerTags = UiKeywordVocabulary.all;

  /// 토큰 일치로 못 잡는 라벨 → 픽커 어휘 별칭.
  /// (AI 분석 taxonomy·과거 온보딩 라벨의 의미 매핑)
  static const Map<String, List<String>> _aliases = {
    '커피': ['카페'],
    '베이커리': ['디저트'],
    '독서': ['서점'],
    '갤러리': ['전시'],
    '예술': ['전시', '현대미술'],
    '문화생활': ['전시', '라이브 공연'],
    '문화/건축': ['디자인', '전시'],
    '건축/디자인': ['디자인', '인테리어'],
    '아웃도어': ['자연', '골목 탐방'],
    '여행': ['도시 여행', '숙소'],
    '슬로우 라이프': ['홈라이프', '조용한 휴식'],
    '공부/작업': ['작업 루틴'],
    '음악': ['플레이리스트'],
    '시장': ['로컬 맛집'],
    '동네': ['로컬 탐방'],
  };

  /// 사용자 취향 태그를 UI keyword vocabulary로 확장한다.
  static Set<String> expandTasteTags(List<String> userTags) {
    final out = <String>{};
    for (final raw in userTags) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      final normalized = UiKeywordVocabulary.normalize(tag);
      if (normalized != null) out.add(normalized);
      out.addAll(
        (_aliases[tag] ?? const []).where(UiKeywordVocabulary.allowed.contains),
      );
      for (final picker in kPickerTags) {
        if (_overlaps(tag, picker)) out.add(picker);
      }
    }
    return out;
  }

  /// 두 라벨이 의미상 겹치는지 — 포함 관계 또는 토큰(2자 이상) 교집합.
  /// 예: '카페/커피'↔'카페', '도시 탐험'↔'도시 여행', '자연 풍경'↔'자연'
  static bool _overlaps(String a, String b) {
    if (a == b || a.contains(b) || b.contains(a)) return true;
    Set<String> tokens(String s) =>
        s.split(RegExp(r'[/·&\s]+')).where((t) => t.length >= 2).toSet();
    return tokens(a).intersection(tokens(b)).isNotEmpty;
  }

  /// 사용자 취향과 일치하는 매거진 태그 목록 (표시용 — 픽커 어휘로 반환).
  static List<String> matchedTags(List<String> userTags, Magazine magazine) {
    final wanted = expandTasteTags(userTags);
    return UiKeywordVocabulary.filter(
      magazine.tags,
    ).where(wanted.contains).toList();
  }

  /// 매거진 점수 = 겹치는 태그 수.
  static int score(List<String> userTags, Magazine magazine) =>
      matchedTags(userTags, magazine).length;

  /// 취향 일치율(%) — 매거진 태그 중 내 취향과 겹치는 비율.
  static int matchPercent(List<String> userTags, Magazine magazine) {
    final normalizedTags = UiKeywordVocabulary.filter(magazine.tags);
    if (normalizedTags.isEmpty) return 0;
    return (matchedTags(userTags, magazine).length /
            normalizedTags.length *
            100)
        .round();
  }

  /// 점수 내림차순 정렬.
  /// [daySeed]가 있으면 동점 매거진을 날짜 기준으로 순환시킨다
  /// (매일 다른 "Today's stand"). 없으면 기존 순서 유지(안정 정렬).
  /// 취향이 없고 시드도 없으면 원래 순서 그대로.
  static List<Magazine> rank(
    List<String>? userTags,
    List<Magazine> magazines, {
    int? daySeed,
  }) {
    final tags = userTags ?? const <String>[];
    if (tags.isEmpty && daySeed == null) return magazines;

    int tieKey(int index, Magazine m) =>
        daySeed == null ? index : _stableHash('${m.title}|$daySeed');

    final indexed = magazines.asMap().entries.toList();
    indexed.sort((a, b) {
      final int diff = score(tags, b.value) - score(tags, a.value);
      if (diff != 0) return diff;
      return tieKey(a.key, a.value).compareTo(tieKey(b.key, b.value));
    });
    return [for (final e in indexed) e.value];
  }

  /// 실행 간에도 값이 같은 문자열 해시 (String.hashCode는 보장이 없음).
  static int _stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  /// 오늘 날짜의 로테이션 시드 (자정 기준으로 매일 바뀜).
  static int todaySeed() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        86400000;
  }

  /// 선반용 배치 — 1순위가 [centerIndex](= 선반의 "Today's Pick" 자리)에
  /// 오도록 2순위부터 좌우로 번갈아 배치한다.
  static List<Magazine> arrangeForShelf(
    List<Magazine> ranked, {
    int centerIndex = 2,
  }) {
    if (ranked.length <= 1) return ranked;
    final int center = centerIndex.clamp(0, ranked.length - 1);

    // slots[i] = i순위 매거진이 놓일 선반 위치
    final slots = <int>[center];
    int left = center - 1;
    int right = center + 1;
    bool goRight = true;
    while (slots.length < ranked.length) {
      final bool canRight = right < ranked.length;
      final bool canLeft = left >= 0;
      if (canRight && (goRight || !canLeft)) {
        slots.add(right++);
      } else if (canLeft) {
        slots.add(left--);
      }
      goRight = !goRight;
    }

    final result = List<Magazine?>.filled(ranked.length, null);
    for (var i = 0; i < ranked.length; i++) {
      result[slots[i]] = ranked[i];
    }
    return result.whereType<Magazine>().toList();
  }
}
