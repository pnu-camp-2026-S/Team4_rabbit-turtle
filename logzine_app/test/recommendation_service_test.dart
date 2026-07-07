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
