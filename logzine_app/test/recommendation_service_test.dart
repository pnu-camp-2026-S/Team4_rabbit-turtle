import 'package:flutter_test/flutter_test.dart';
import 'package:logzine_app/models/magazine.dart';
import 'package:logzine_app/services/recommendation_service.dart';

Magazine _mag(String title, List<String> tags) =>
    Magazine(title: title, tagline: '', issue: '', coverUrl: '', tags: tags);

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
      expect(RecommendationService.matchedTags(['카페', '재즈'], cafe), ['카페']);
      expect(RecommendationService.matchedTags(['없음'], cafe), isEmpty);
    });
  });

  group('어휘 브리지 (expandTasteTags)', () {
    test('AI 분석 taxonomy 라벨이 픽커 어휘로 매칭된다', () {
      // '카페/커피'(분석기) → '카페'(매거진 태그)
      expect(
        RecommendationService.matchedTags(['카페/커피'], cafe),
        contains('카페'),
      );
      // '전시/예술' → Frieze류 매거진의 '전시'
      final frieze = _mag('Frieze', ['전시', '현대미술', '디자인']);
      expect(
        RecommendationService.matchedTags(['전시/예술'], frieze),
        contains('전시'),
      );
    });

    test('과거 온보딩 라벨(토큰 겹침)이 매칭된다', () {
      // '도시 탐험' → '도시 여행' (토큰 "도시" 겹침)
      expect(
        RecommendationService.matchedTags(['도시 탐험'], travel),
        contains('도시 여행'),
      );
      // '수공예 & 휴식' → '공예' (부분 포함)
      expect(
        RecommendationService.matchedTags(['수공예 & 휴식'], space),
        contains('공예'),
      );
    });

    test('별칭 매핑: 문화생활 → 전시', () {
      final frieze = _mag('Frieze', ['전시', '현대미술', '디자인']);
      expect(
        RecommendationService.matchedTags(['문화생활'], frieze),
        contains('전시'),
      );
    });

    test('별칭 매핑: 호텔 ↔ 숙소는 직접 매칭으로 본다', () {
      expect(RecommendationService.matchedTags(['호텔'], travel), contains('숙소'));
      final hotel = _mag('Hotel Weekend', ['호텔', '디자인']);
      expect(RecommendationService.matchedTags(['숙소'], hotel), contains('호텔'));
    });

    test('의미 없는 태그는 여전히 매칭 안 된다', () {
      expect(RecommendationService.matchedTags(['우주비행'], cafe), isEmpty);
    });

    test('브리지를 거친 rank — 분석기 어휘로도 추천 정렬이 동작한다', () {
      final ranked = RecommendationService.rank(['카페/커피', '도시 탐험'], all);
      expect(ranked.first.title, 'Drift'); // 카페+도시 여행 2개 일치
    });
  });

  group('matchPercent / 데일리 로테이션', () {
    test('일치율 = 기준 취향 키워드 중 매거진이 커버하는 비율', () {
      expect(RecommendationService.matchPercent(['카페', '도시 여행'], cafe), 100);
      expect(RecommendationService.matchPercent(['카페', '재즈'], cafe), 50);
      expect(RecommendationService.matchPercent(['카페'], cafe), 100);
      expect(RecommendationService.matchPercent(['없음'], cafe), 0);
    });

    test('daySeed가 같으면 순서도 같다 (결정적)', () {
      final a = RecommendationService.rank(null, all, daySeed: 42);
      final b = RecommendationService.rank(null, all, daySeed: 42);
      expect(a.map((m) => m.title), b.map((m) => m.title));
    });

    test('daySeed가 있어도 점수 우선순위는 유지된다', () {
      final ranked = RecommendationService.rank(['바이닐', '재즈'], all, daySeed: 7);
      expect(ranked.first.title, 'Wax Poetics'); // 2개 일치는 항상 1위
    });
  });

  group('RecommendationService.arrangeForShelf', () {
    test('1순위가 가운데(centerIndex)에 온다', () {
      final ranked = RecommendationService.rank(['바이닐'], all);
      final shelf = RecommendationService.arrangeForShelf(ranked);
      expect(shelf[2].title, 'Wax Poetics');
      expect(shelf.length, all.length);
      expect(
        shelf.map((m) => m.title).toSet(),
        all.map((m) => m.title).toSet(),
      );
    });

    test('매거진이 적어도 안전하다', () {
      expect(RecommendationService.arrangeForShelf([cafe]).single, cafe);
      expect(RecommendationService.arrangeForShelf(const []), isEmpty);
    });
  });

  group('RecommendationService stand UX helpers', () {
    test('첫 선반은 최대 6개로 직접 매칭과 발견 후보를 함께 구성한다', () {
      final shelf = RecommendationService.buildInitialShelf(
        ['카페', '도시 여행', '재즈'],
        all,
        daySeed: 1,
      );
      expect(shelf.length, all.length);
      expect(shelf, contains(cafe));
      expect(shelf, contains(music));
    });

    test('키워드 선택은 선반 안의 직접 매칭 후보 인덱스를 찾는다', () {
      final shelf = RecommendationService.buildInitialShelf([
        '카페',
        '도시 여행',
        '재즈',
      ], all);
      final index = RecommendationService.focusIndexForTaste(shelf, '재즈');
      expect(index, isNotNull);
      expect(shelf[index!].title, 'Wax Poetics');
    });

    test('직접 매칭이 없으면 가까운 fallback 목록을 구분한다', () {
      final result = RecommendationService.listForTaste(['와인'], all);
      expect(result.kind, RecommendationMatchKind.fallback);
      expect(result.magazines.map((m) => m.title), contains('Drift'));
    });

    test('직접 매칭도 fallback도 없으면 empty 결과를 반환한다', () {
      final result = RecommendationService.listForTaste(['우주비행'], all);
      expect(result.kind, RecommendationMatchKind.empty);
      expect(result.magazines, isEmpty);
    });
  });
}
