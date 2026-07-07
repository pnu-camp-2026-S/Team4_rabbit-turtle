import '../models/magazine.dart';

/// 취향 태그 ∩ 매거진 태그 기반 추천 로직.
/// Firestore 의존이 없는 순수 함수 — 단위 테스트로 검증한다.
///
/// 어휘 브리지: 사용자 tasteTags는 출처가 여러 갈래다
/// (취향 픽커 한국어 태그 / AI 사진 분석 taxonomy 라벨 / 과거 온보딩 라벨).
/// [expandTasteTags]가 어떤 어휘든 매거진 태그(픽커 어휘)로 변환해 비교한다.
class RecommendationService {
  /// 매거진 tags에 쓰이는 표준 어휘 = 취향 픽커(taste_picker_page)의 태그.
  /// ⚠️ 픽커 태그를 바꾸면 여기도 함께 갱신할 것.
  static const List<String> kPickerTags = [
    // 음식
    '카페', '디저트', '와인', '집밥', '파인다이닝', '로컬 맛집',
    // 패션
    '미니멀', '빈티지', '스트릿', '디자이너 브랜드', '액세서리', '데일리룩',
    // 공간
    '인테리어', '가구', '호텔', '전시 공간', '동네 가게', '작업실',
    // 여행
    '도시 여행', '로컬', '숙소', '산책', '자연', '주말 여행',
    // 예술
    '전시', '현대미술', '공예', '디자인', '일러스트', '사진',
    // 음악
    '인디', '재즈', '플레이리스트', '공연', '바이닐', '사운드트랙',
  ];

  /// 토큰 일치로 못 잡는 라벨 → 픽커 어휘 별칭.
  /// (AI 분석 taxonomy·과거 온보딩 라벨의 의미 매핑)
  static const Map<String, List<String>> _aliases = {
    '커피': ['카페'],
    '베이커리': ['디저트'],
    '독서': ['서점'], // 픽커에 없어 매칭 안 되지만 의미 기록용
    '갤러리': ['전시'],
    '예술': ['전시', '현대미술'],
    '문화생활': ['전시', '공연'],
    '문화/건축': ['디자인', '전시'],
    '건축/디자인': ['디자인', '인테리어'],
    '아웃도어': ['자연', '산책'],
    '여행': ['도시 여행', '주말 여행'],
    '슬로우 라이프': ['집밥', '산책'],
    '공부/작업': ['작업실'],
    '음악': ['플레이리스트'],
    '시장': ['동네 가게'],
    '동네': ['동네 가게'],
  };

  /// 사용자 취향 태그를 픽커 어휘로 확장한다.
  /// 원본 태그 + 별칭 + 토큰/부분일치로 잡히는 픽커 태그를 모두 포함.
  static Set<String> expandTasteTags(List<String> userTags) {
    final out = <String>{};
    for (final raw in userTags) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      out.add(tag); // 원본 유지 (픽커 어휘면 그대로 일치)
      out.addAll(_aliases[tag] ?? const []);
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
    Set<String> tokens(String s) => s
        .split(RegExp(r'[/·&\s]+'))
        .where((t) => t.length >= 2)
        .toSet();
    return tokens(a).intersection(tokens(b)).isNotEmpty;
  }

  /// 사용자 취향과 일치하는 매거진 태그 목록 (표시용 — 픽커 어휘로 반환).
  static List<String> matchedTags(List<String> userTags, Magazine magazine) {
    final wanted = expandTasteTags(userTags);
    return magazine.tags.where(wanted.contains).toList();
  }

  /// 매거진 점수 = 겹치는 태그 수.
  static int score(List<String> userTags, Magazine magazine) =>
      matchedTags(userTags, magazine).length;

  /// 점수 내림차순 정렬. 동점은 기존 순서 유지(안정 정렬).
  /// 취향이 없으면(비로그인/온보딩 전) 원래 순서 그대로.
  static List<Magazine> rank(
    List<String>? userTags,
    List<Magazine> magazines,
  ) {
    if (userTags == null || userTags.isEmpty) return magazines;
    final indexed = magazines.asMap().entries.toList();
    indexed.sort((a, b) {
      final int diff = score(userTags, b.value) - score(userTags, a.value);
      return diff != 0 ? diff : a.key - b.key;
    });
    return [for (final e in indexed) e.value];
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
