import '../models/magazine.dart';
import '../models/taste_taxonomy.dart';

enum RecommendationMatchKind { direct, fallback, empty }

class RecommendationListResult {
  const RecommendationListResult({
    required this.magazines,
    required this.kind,
    required this.basis,
  });

  final List<Magazine> magazines;
  final RecommendationMatchKind kind;
  final List<String> basis;
}

/// 취향 태그 ∩ 매거진 태그 기반 추천 로직.
/// Firestore 의존이 없는 순수 함수 — 단위 테스트로 검증한다.
///
/// 어휘 브리지: 사용자 tasteTags는 출처가 여러 갈래다
/// (취향 픽커 한국어 태그 / AI 사진 분석 라벨 / 과거 온보딩 라벨).
/// [expandTasteTags]가 어떤 어휘든 표준 어휘(taste_taxonomy)로 변환해 비교한다.
///
/// 어휘·계층은 전부 `models/taste_taxonomy.dart`에서 온다 — 여기서 다시
/// 정의하지 않으므로 어휘가 어긋날 수 없다.
class RecommendationService {
  /// 매거진 tags·사용자 tasteTags에 쓰이는 표준 어휘 (taxonomy 단일 출처).
  static final List<String> kPickerTags = kAllTasteKeywords;

  /// 과거 어휘 → 현재 키워드 (taxonomy 단일 출처).
  static const Map<String, List<String>> _aliases = kLegacyTasteAliases;

  /// 세부 취향이 직접 일치하지 않을 때의 폴백 후보.
  /// 1차: 같은 카테고리의 형제 키워드 (계층에서 자동 도출)
  /// 2차: 카테고리를 넘나드는 의미적 인접 관계 (taxonomy의 최소 보정표)
  ///
  /// 세분화(축구/농구, 강아지/고양이…)를 해도 매칭이 끊기지 않는 이유가
  /// 바로 이 형제 폴백이다.
  static List<String> neighborsOf(String tag) => [
    ...siblingsOf(tag),
    ...?kCrossCategoryNeighbors[tag],
  ];

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
    Set<String> tokens(String s) =>
        s.split(RegExp(r'[/·&\s]+')).where((t) => t.length >= 2).toSet();
    return tokens(a).intersection(tokens(b)).isNotEmpty;
  }

  static String _keyOf(Magazine magazine) =>
      magazine.id.isNotEmpty ? magazine.id : magazine.title;

  static Set<String> _expandedNearbyTags(List<String> userTags) {
    final expanded = expandTasteTags(userTags);
    final out = <String>{};
    for (final tag in expanded) {
      out.addAll(neighborsOf(tag));
    }
    return out.difference(expanded);
  }

  static int fallbackScore(List<String> userTags, Magazine magazine) {
    final nearby = _expandedNearbyTags(userTags);
    if (nearby.isEmpty) return 0;
    return magazine.tags.where(nearby.contains).length;
  }

  static List<Magazine> _rankBy(
    List<Magazine> magazines,
    int Function(Magazine magazine) scoreOf, {
    int? daySeed,
  }) {
    final indexed = magazines.asMap().entries.toList();
    indexed.sort((a, b) {
      final int diff = scoreOf(b.value) - scoreOf(a.value);
      if (diff != 0) return diff;
      if (daySeed == null) return a.key.compareTo(b.key);
      return _stableHash(
        '${a.value.title}|$daySeed',
      ).compareTo(_stableHash('${b.value.title}|$daySeed'));
    });
    return [for (final e in indexed) e.value];
  }

  /// 사용자 취향과 일치하는 매거진 태그 목록 (표시용 — 픽커 어휘로 반환).
  static List<String> matchedTags(List<String> userTags, Magazine magazine) {
    final wanted = expandTasteTags(userTags);
    return magazine.tags.where(wanted.contains).toList();
  }

  /// 매거진 점수 = 겹치는 태그 수.
  static int score(List<String> userTags, Magazine magazine) =>
      matchedTags(userTags, magazine).length;

  static List<String> coveredTasteTags(
    List<String> userTags,
    Magazine magazine,
  ) {
    final covered = <String>[];
    for (final raw in userTags) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      if (matchedTags([tag], magazine).isNotEmpty) covered.add(tag);
    }
    return covered;
  }

  /// 취향 일치율(%) — 기준 취향 키워드 중 이 매거진이 커버하는 비율.
  static int matchPercent(List<String> userTags, Magazine magazine) {
    final basis = userTags.where((tag) => tag.trim().isNotEmpty).toList();
    if (basis.isEmpty) return 0;
    return (coveredTasteTags(basis, magazine).length / basis.length * 100)
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

  static List<Magazine> buildInitialShelf(
    List<String> userTags,
    List<Magazine> magazines, {
    int maxItems = 6,
    int directTarget = 4,
    int? daySeed,
  }) {
    if (magazines.isEmpty) return const [];
    final direct = _rankBy(
      magazines.where((m) => score(userTags, m) > 0).toList(),
      (m) => score(userTags, m),
      daySeed: daySeed,
    );
    final directKeys = direct.map(_keyOf).toSet();
    final fallback = _rankBy(
      magazines
          .where((m) => !directKeys.contains(_keyOf(m)))
          .where((m) => fallbackScore(userTags, m) > 0)
          .toList(),
      (m) => fallbackScore(userTags, m),
      daySeed: daySeed,
    );

    final selected = <Magazine>[];
    selected.addAll(direct.take(directTarget));
    selected.addAll(fallback.take(maxItems - selected.length));

    if (selected.length < maxItems) {
      final used = selected.map(_keyOf).toSet();
      final discovery = _rankBy(
        magazines.where((m) => !used.contains(_keyOf(m))).toList(),
        (m) => score(userTags, m),
        daySeed: daySeed,
      );
      selected.addAll(discovery.take(maxItems - selected.length));
    }

    return arrangeForShelf(selected.take(maxItems).toList());
  }

  static int? focusIndexForTaste(List<Magazine> shelf, String selectedTaste) {
    if (shelf.isEmpty) return null;
    final direct = _rankBy(
      shelf.where((m) => score([selectedTaste], m) > 0).toList(),
      (m) => score([selectedTaste], m),
    );
    if (direct.isNotEmpty) {
      final key = _keyOf(direct.first);
      return shelf.indexWhere((m) => _keyOf(m) == key);
    }

    final fallback = _rankBy(
      shelf.where((m) => fallbackScore([selectedTaste], m) > 0).toList(),
      (m) => fallbackScore([selectedTaste], m),
    );
    if (fallback.isNotEmpty) {
      final key = _keyOf(fallback.first);
      return shelf.indexWhere((m) => _keyOf(m) == key);
    }
    return null;
  }

  static RecommendationListResult listForTaste(
    List<String> tasteBasis,
    List<Magazine> magazines, {
    int? daySeed,
  }) {
    final basis = tasteBasis.where((tag) => tag.trim().isNotEmpty).toList();
    if (basis.isEmpty) {
      return RecommendationListResult(
        magazines: _rankBy(magazines, (_) => 0, daySeed: daySeed),
        kind: magazines.isEmpty
            ? RecommendationMatchKind.empty
            : RecommendationMatchKind.direct,
        basis: basis,
      );
    }

    final direct = _rankBy(
      magazines.where((m) => score(basis, m) > 0).toList(),
      (m) => score(basis, m),
      daySeed: daySeed,
    );
    if (direct.isNotEmpty) {
      return RecommendationListResult(
        magazines: direct,
        kind: RecommendationMatchKind.direct,
        basis: basis,
      );
    }

    final fallback = _rankBy(
      magazines.where((m) => fallbackScore(basis, m) > 0).toList(),
      (m) => fallbackScore(basis, m),
      daySeed: daySeed,
    );
    if (fallback.isNotEmpty) {
      return RecommendationListResult(
        magazines: fallback,
        kind: RecommendationMatchKind.fallback,
        basis: basis,
      );
    }

    return RecommendationListResult(
      magazines: const [],
      kind: RecommendationMatchKind.empty,
      basis: basis,
    );
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
