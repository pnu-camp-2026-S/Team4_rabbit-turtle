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
    '카페', '커피', '디저트', '베이커리', '브런치', '전통차', '와인', '로컬 맛집',
    // 패션
    '미니멀', '빈티지', '스트릿', '클래식', '디자이너 브랜드', '스포츠웨어', '액세서리', '데일리룩',
    // 공간
    '인테리어', '가구', '한옥', '호텔', '전시 공간', '서점', '정원', '복합문화공간',
    // 여행
    '도시 여행', '해외 도시', '랜드마크', '골목 탐방', '자연', '숙소', '미식 여행', '스포츠 여행',
    // 예술
    '전시', '현대미술', '건축', '공예', '디자인', '일러스트', '사진', '아트페어',
    // 음악
    '인디', '재즈', '라이브 공연', '페스티벌', '플레이리스트', '바이닐', '클래식', '사운드트랙',
    // 스포츠
    '축구', '야구', '러닝', '요가', '클라이밍', '스포츠 관람', '경기장 투어', '스포츠 여행',
    // 라이프
    '독서', '웰니스', '작업 루틴', '홈라이프', '반려생활', '취미 수집', '조용한 휴식', '로컬 탐방',
  ];

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

  /// 직접 매칭이 없을 때만 쓰는 가까운 취향 후보.
  /// 기존 키워드 구조는 유지하고 현재 취향 선택기 어휘 안의 키워드로만 확장한다.
  static const Map<String, List<String>> _fallbackNeighbors = {
    '와인': ['미식 여행', '로컬 맛집', '브런치', '카페', '호텔'],
    '전통차': ['카페', '브런치', '한옥', '조용한 휴식'],
    '베이커리': ['디저트', '브런치', '카페'],
    '커피': ['카페', '브런치', '로컬 맛집'],
    '호텔': ['숙소', '조용한 휴식', '도시 여행'],
    '한옥': ['전통차', '건축', '조용한 휴식'],
    '정원': ['자연', '웰니스', '조용한 휴식'],
    '클래식': ['재즈', '바이닐', '사운드트랙'],
    '플레이리스트': ['인디', '재즈', '바이닐'],
    '사운드트랙': ['플레이리스트', '인디', '바이닐'],
    '페스티벌': ['라이브 공연', '인디', '스포츠 관람'],
    '스포츠웨어': ['러닝', '요가', '스포츠 관람'],
    '스포츠 여행': ['스포츠 관람', '경기장 투어', '도시 여행'],
    '야구': ['스포츠 관람', '경기장 투어'],
    '클라이밍': ['러닝', '자연', '웰니스'],
    '반려생활': ['홈라이프', '정원', '조용한 휴식'],
    '일러스트': ['디자인', '사진', '아트페어'],
    '액세서리': ['데일리룩', '디자이너 브랜드', '미니멀'],
    '해외 도시': ['도시 여행', '랜드마크', '숙소'],
    '랜드마크': ['도시 여행', '건축', '사진'],
  };

  static const Map<String, List<String>> _categoryTags = {
    'FOOD': ['카페', '커피', '디저트', '베이커리', '브런치', '전통차', '와인', '로컬 맛집'],
    'FASHION': ['미니멀', '빈티지', '스트릿', '클래식', '디자이너 브랜드', '스포츠웨어', '액세서리', '데일리룩'],
    'SPACE': ['인테리어', '가구', '한옥', '호텔', '전시 공간', '서점', '정원', '복합문화공간'],
    'TRAVEL': ['도시 여행', '해외 도시', '랜드마크', '골목 탐방', '자연', '숙소', '미식 여행', '스포츠 여행'],
    'ART': ['전시', '현대미술', '건축', '공예', '디자인', '일러스트', '사진', '아트페어'],
    'MUSIC': ['인디', '재즈', '라이브 공연', '페스티벌', '플레이리스트', '바이닐', '클래식', '사운드트랙'],
    'SPORTS': ['축구', '야구', '러닝', '요가', '클라이밍', '스포츠 관람', '경기장 투어', '스포츠 여행'],
    'LIFESTYLE': ['독서', '웰니스', '작업 루틴', '홈라이프', '반려생활', '취미 수집', '조용한 휴식', '로컬 탐방'],
  };

  /// 사용자 취향 태그를 픽커 어휘로 확장한다.
  /// 원본 태그 + 별칭 + 토큰/부분일치로 잡히는 픽커 태그를 모두 포함.
  static Set<String> expandTasteTags(List<String> userTags) {
    final out = <String>{};
    for (final raw in userTags) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      out.add(tag); // 원본 유지 (픽커 어휘면 그대로 일치)
      out.addAll((_aliases[tag] ?? const []).where(_isPickerTag));
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
    return _filterPickerTags(magazine.tags).where(wanted.contains).toList();
  }

  /// 매거진 점수 = 겹치는 태그 수.
  static int score(List<String> userTags, Magazine magazine) =>
      matchedTags(userTags, magazine).length;

  /// 취향 일치율(%) — 내 취향 키워드 중 이 매거진이 커버하는 비율.
  /// 예: 사용자가 '카페' 하나를 눌렀고 매거진 태그에 '카페'가 있으면 100%.
  static int matchPercent(List<String> userTags, Magazine magazine) {
    final covered = _coveredTasteCount(userTags, magazine);
    final total = _countableTasteTags(userTags).length;
    if (total == 0) return 0;
    return (covered / total * 100).round();
  }

  static List<String> _countableTasteTags(List<String> userTags) {
    return [
      for (final raw in userTags)
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
  }

  static int _coveredTasteCount(List<String> userTags, Magazine magazine) {
    final magazineTags = _filterPickerTags(magazine.tags).toSet();
    var covered = 0;
    for (final raw in _countableTasteTags(userTags)) {
      if (expandTasteTags([raw]).intersection(magazineTags).isNotEmpty) {
        covered++;
      }
    }
    return covered;
  }

  /// 선택 키워드/취향을 하나도 만족하지 않는 매거진을 제외한다.
  static List<Magazine> matchingOnly(
    List<String> userTags,
    List<Magazine> magazines, {
    int? daySeed,
  }) {
    return rank(
      userTags,
      magazines,
      daySeed: daySeed,
    ).where((magazine) => score(userTags, magazine) > 0).toList();
  }

  /// 직접 매칭이 없을 때 가까운 키워드/같은 상위 카테고리 후보를 찾는다.
  static List<Magazine> fallbackForKeyword(
    String keyword,
    List<Magazine> magazines, {
    int? daySeed,
  }) {
    final related = relatedFallbackTags(keyword);
    if (related.isEmpty) return const [];
    return rank(
      related,
      magazines,
      daySeed: daySeed,
    ).where((magazine) => score(related, magazine) > 0).toList();
  }

  static List<String> relatedFallbackTags(String keyword) {
    final normalized = _normalizePickerTag(keyword) ?? keyword.trim();
    final related = <String>{...(_fallbackNeighbors[normalized] ?? const [])};
    related.addAll(_sameCategoryTags(normalized));
    related.remove(normalized);
    return _filterPickerTags(related);
  }

  static bool _isPickerTag(String tag) => kPickerTags.contains(tag);

  static List<String> _filterPickerTags(Iterable<String> tags) {
    final out = <String>[];
    for (final raw in tags) {
      final normalized = _normalizePickerTag(raw);
      if (normalized != null && !out.contains(normalized)) {
        out.add(normalized);
      }
    }
    return out;
  }

  static String? _normalizePickerTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    for (final tag in kPickerTags) {
      if (tag == trimmed) return tag;
    }
    for (final tag in kPickerTags) {
      if (_overlaps(trimmed, tag)) return tag;
    }
    return null;
  }

  static List<String> _sameCategoryTags(String tag) {
    for (final entry in _categoryTags.entries) {
      if (entry.value.contains(tag)) return entry.value;
    }
    return const [];
  }

  /// 홈 선반용: 취향 매칭 후보를 먼저 놓고, 아직 취향과 겹치지 않는 신규 후보를 섞는다.
  static List<Magazine> blendedStand(
    List<String> userTags,
    List<Magazine> magazines, {
    int matchLimit = 4,
    int freshLimit = 2,
    int totalLimit = 6,
    int? daySeed,
  }) {
    final matched = matchingOnly(
      userTags,
      magazines,
      daySeed: daySeed,
    ).take(matchLimit);
    final selectedIds = {
      for (final magazine in matched) _magazineKey(magazine),
    };

    final fresh = rank(const [], [
      for (final magazine in magazines)
        if (!selectedIds.contains(_magazineKey(magazine)) &&
            score(userTags, magazine) == 0)
          magazine,
    ], daySeed: daySeed).take(freshLimit);

    final result = <Magazine>[...matched, ...fresh];
    final used = {for (final magazine in result) _magazineKey(magazine)};
    if (result.length < totalLimit) {
      for (final magazine in rank(userTags, magazines, daySeed: daySeed)) {
        if (!used.add(_magazineKey(magazine))) continue;
        result.add(magazine);
        if (result.length >= totalLimit) break;
      }
    }
    return result.take(totalLimit).toList();
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

    int tieKey(int index, Magazine m) => daySeed == null
        ? index
        : _stableHash('${m.title}|$daySeed');

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

  static String _magazineKey(Magazine magazine) =>
      magazine.id.isEmpty ? magazine.title : magazine.id;

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
