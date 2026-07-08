import 'package:flutter_test/flutter_test.dart';
import 'package:logzine_app/models/magazine.dart';
import 'package:logzine_app/services/recommendation_service.dart';

Magazine _mag(String title, List<String> tags) => Magazine(
      title: title,
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: tags,
    );

void main() {
  final cafe = _mag('Drift', ['카페', '도시 여행', '로컬 맛집']);
  final space = _mag('ROOM NOTE', ['인테리어', '가구', '공예']);
  final music = _mag('Wax Poetics', ['바이닐', '재즈', '인디']);
  final travel = _mag('SUITCASE', ['도시 여행', '숙소', '주말 여행']);
  final all = [space, music, cafe, travel];

  group('RecommendationService.rank', () {
    test('취향과 겹치는 태그가 많은 매거진이 앞으로 온다', () {
      final ranked = RecommendationService.rank(['카페', '도시 여행'], all);
      expect(ranked.first.title, 'Drift'); // 2개 일치
      expect(ranked[1].title, 'SUITCASE'); // 1개 일치
    });

    test('취향이 없으면 원래 순서를 유지한다', () {
      expect(RecommendationService.rank(null, all), all);
      expect(RecommendationService.rank([], all), all);
    });

    test('동점 매거진은 기존 순서를 유지한다 (안정 정렬)', () {
      final ranked = RecommendationService.rank(['없는태그'], all);
      expect(ranked.map((m) => m.title), all.map((m) => m.title));
    });
  });

  group('RecommendationService.matchedTags', () {
    test('일치하는 태그만 돌려준다', () {
      expect(
        RecommendationService.matchedTags(['카페', '재즈'], cafe),
        ['카페'],
      );
      expect(RecommendationService.matchedTags(['없음'], cafe), isEmpty);
    });
  });

  group('어휘 브리지 (expandTasteTags)', () {
    test('AI 분석 taxonomy 라벨이 픽커 어휘로 매칭된다', () {
      // '카페/커피'(분석기) → '카페'(매거진 태그)
      expect(RecommendationService.matchedTags(['카페/커피'], cafe),
          contains('카페'));
      // '전시/예술' → Frieze류 매거진의 '전시'
      final frieze = _mag('Frieze', ['전시', '현대미술', '디자인']);
      expect(RecommendationService.matchedTags(['전시/예술'], frieze),
          contains('전시'));
    });

    test('과거 온보딩 라벨(토큰 겹침)이 매칭된다', () {
      // '도시 탐험' → '도시 여행' (토큰 "도시" 겹침)
      expect(RecommendationService.matchedTags(['도시 탐험'], travel),
          contains('도시 여행'));
      // '수공예 & 휴식' → '공예' (부분 포함)
      expect(RecommendationService.matchedTags(['수공예 & 휴식'], space),
          contains('공예'));
    });

    test('별칭 매핑: 문화생활 → 전시', () {
      final frieze = _mag('Frieze', ['전시', '현대미술', '디자인']);
      expect(RecommendationService.matchedTags(['문화생활'], frieze),
          contains('전시'));
    });

    test('의미 없는 태그는 여전히 매칭 안 된다', () {
      expect(RecommendationService.matchedTags(['우주비행'], cafe), isEmpty);
    });

    test('브리지를 거친 rank — 분석기 어휘로도 추천 정렬이 동작한다', () {
      final ranked =
          RecommendationService.rank(['카페/커피', '도시 탐험'], all);
      expect(ranked.first.title, 'Drift'); // 카페+도시 여행 2개 일치
    });
  });

  group('matchPercent / 데일리 로테이션', () {
    test('일치율 = 사용자 취향 중 매거진이 커버하는 비율', () {
      expect(
        RecommendationService.matchPercent(['카페', '도시 여행'], cafe),
        100, // 사용자 취향 2개를 모두 커버
      );
      expect(RecommendationService.matchPercent(['카페', '재즈'], cafe), 50);
      expect(RecommendationService.matchPercent(['없음'], cafe), 0);
    });

    test('daySeed가 같으면 순서도 같다 (결정적)', () {
      final a = RecommendationService.rank(null, all, daySeed: 42);
      final b = RecommendationService.rank(null, all, daySeed: 42);
      expect(a.map((m) => m.title), b.map((m) => m.title));
    });

    test('daySeed가 있어도 점수 우선순위는 유지된다', () {
      final ranked =
          RecommendationService.rank(['바이닐', '재즈'], all, daySeed: 7);
      expect(ranked.first.title, 'Wax Poetics'); // 2개 일치는 항상 1위
    });
  });

  group('직접 매칭 없음 fallback', () {
    test('직접 매칭이 없으면 가까운 취향 후보를 찾는다', () {
      final direct = RecommendationService.matchingOnly(['와인'], all);
      final fallback = RecommendationService.fallbackForKeyword('와인', all);

      expect(direct, isEmpty);
      expect(fallback.map((m) => m.title), contains('Drift'));
      expect(
        RecommendationService.relatedFallbackTags('와인'),
        containsAll(['미식 여행', '로컬 맛집', '브런치', '카페']),
      );
    });

    test('fallback 후보도 없으면 빈 목록을 유지한다', () {
      final fallback = RecommendationService.fallbackForKeyword('우주비행', all);
      expect(fallback, isEmpty);
    });
  });

  group('RecommendationService.blendedStand', () {
    test('취향 매칭 후보와 신규 후보를 섞어 6개까지 만든다', () {
      final m1 = _mag('Cafe 1', ['카페']);
      final m2 = _mag('Cafe 2', ['카페', '디저트']);
      final m3 = _mag('Cafe 3', ['카페']);
      final m4 = _mag('Cafe 4', ['카페']);
      final m5 = _mag('Cafe 5', ['카페']);
      final fresh1 = _mag('Fresh 1', ['재즈']);
      final fresh2 = _mag('Fresh 2', ['전시']);
      final mixed = RecommendationService.blendedStand(
        ['카페'],
        [m1, m2, m3, m4, m5, fresh1, fresh2],
        daySeed: 1,
      );

      expect(mixed.length, 6);
      expect(mixed.where((m) => m.tags.contains('카페')).length, 4);
      expect(
        mixed.where((m) => !m.tags.contains('카페')).map((m) => m.title),
        containsAll(['Fresh 1', 'Fresh 2']),
      );
    });
  });

  group('RecommendationService.arrangeForShelf', () {
    test('1순위가 가운데(centerIndex)에 온다', () {
      final ranked = RecommendationService.rank(['바이닐'], all);
      final shelf = RecommendationService.arrangeForShelf(ranked);
      expect(shelf[2].title, 'Wax Poetics');
      expect(shelf.length, all.length);
      expect(shelf.map((m) => m.title).toSet(), all.map((m) => m.title).toSet());
    });

    test('매거진이 적어도 안전하다', () {
      expect(RecommendationService.arrangeForShelf([cafe]).single, cafe);
      expect(RecommendationService.arrangeForShelf(const []), isEmpty);
    });
  });
}
