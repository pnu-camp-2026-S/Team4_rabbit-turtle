import '../models/magazine.dart';

/// 취향 태그 ∩ 매거진 태그 기반 추천 로직.
/// Firestore 의존이 없는 순수 함수 — 단위 테스트로 검증한다.
/// 어휘 기준: 취향 픽커(taste_picker_page)와 매거진 tags는 같은 한국어 태그를 쓴다.
class RecommendationService {
  /// 사용자 취향과 일치하는 매거진 태그 목록.
  static List<String> matchedTags(List<String> userTags, Magazine magazine) {
    final wanted = userTags.toSet();
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
