import 'package:flutter_test/flutter_test.dart';
import 'package:logzine_app/models/magazine.dart';
import 'package:logzine_app/models/taste_taxonomy.dart';
import 'package:logzine_app/services/recommendation_service.dart';

void main() {
  group('taste_taxonomy 불변식', () {
    test('키워드는 전체에서 유일하다 (계층 폴백이 모호해지지 않도록)', () {
      final seen = <String, String>{};
      for (final category in kTasteTaxonomy) {
        for (final keyword in category.keywords) {
          expect(
            seen.containsKey(keyword),
            isFalse,
            reason:
                "'$keyword'가 ${seen[keyword]}와 ${category.id} 두 카테고리에 중복됨",
          );
          seen[keyword] = category.id;
        }
      }
    });

    test('별칭이 가리키는 값은 모두 실제 키워드다', () {
      for (final entry in kLegacyTasteAliases.entries) {
        for (final target in entry.value) {
          expect(
            kAllTasteKeywordSet.contains(target),
            isTrue,
            reason: "별칭 '${entry.key}' → '$target'가 taxonomy에 없음",
          );
        }
      }
    });

    test('인접 관계의 키·값이 모두 실제 키워드다', () {
      for (final entry in kCrossCategoryNeighbors.entries) {
        expect(
          kAllTasteKeywordSet.contains(entry.key),
          isTrue,
          reason: "인접 관계 키 '${entry.key}'가 taxonomy에 없음",
        );
        for (final target in entry.value) {
          expect(
            kAllTasteKeywordSet.contains(target),
            isTrue,
            reason: "'${entry.key}' → '$target'가 taxonomy에 없음",
          );
        }
      }
    });

    test('siblingsOf는 같은 카테고리의 자기 자신 제외 키워드를 준다', () {
      expect(siblingsOf('축구'), contains('농구'));
      expect(siblingsOf('축구'), contains('스포츠 관람'));
      expect(siblingsOf('축구'), isNot(contains('축구')));
      expect(siblingsOf('강아지'), contains('고양이'));
      expect(siblingsOf('힙합'), contains('락'));
      expect(siblingsOf('없는키워드'), isEmpty);
    });

    test('추천 엔진의 표준 어휘 = taxonomy 전체 키워드', () {
      expect(RecommendationService.kPickerTags, equals(kAllTasteKeywords));
    });
  });

  group('매거진 카탈로그가 taxonomy를 커버한다', () {
    final catalogTags = {for (final m in kMagazines) ...m.tags};

    test('매거진 태그는 전부 taxonomy 어휘다 (죽은 태그 금지)', () {
      final dead = catalogTags.difference(kAllTasteKeywordSet);
      expect(
        dead,
        isEmpty,
        reason: 'AI가 절대 만들 수 없는 태그라 매칭에 쓰이지 못함: $dead',
      );
    });

    test('모든 취향 키워드에 최소 1개의 매거진이 있다 (매칭 0 방지)', () {
      final uncovered = kAllTasteKeywordSet.difference(catalogTags);
      expect(
        uncovered,
        isEmpty,
        reason: '이 취향이 나오면 직접 매칭될 매거진이 없음: $uncovered',
      );
    });

    test('모든 카테고리가 매거진으로 대표된다', () {
      for (final category in kTasteTaxonomy) {
        final covered = category.keywords.where(catalogTags.contains);
        expect(
          covered,
          isNotEmpty,
          reason: '${category.id}(${category.label}) 카테고리를 다루는 매거진이 없음',
        );
      }
    });
  });

  group('세분화해도 매칭이 끊기지 않는다 (계층 폴백)', () {
    // 농구 매거진은 없고 축구 매거진만 있는 상황
    const soccerMag = Magazine(
      title: 'PITCH',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['축구', '스포츠 관람'],
    );
    const interiorMag = Magazine(
      title: 'ROOM',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['인테리어', '가구'],
    );

    test('농구를 좋아하면 직접 매칭은 없지만 같은 카테고리로 폴백된다', () {
      expect(RecommendationService.score(['농구'], soccerMag), 0);
      expect(
        RecommendationService.fallbackScore(['농구'], soccerMag),
        greaterThan(0),
      );

      final result = RecommendationService.listForTaste([
        '농구',
      ], [soccerMag, interiorMag]);
      expect(result.kind, RecommendationMatchKind.fallback);
      expect(result.magazines.first.title, 'PITCH');
    });

    test('옛 태그 반려생활은 세분화된 강아지/고양이로 확장된다', () {
      final expanded = RecommendationService.expandTasteTags(['반려생활']);
      expect(expanded, containsAll(['강아지', '고양이']));
    });

    test('축구 취향은 축구 매거진에 직접 매칭된다', () {
      expect(RecommendationService.score(['축구'], soccerMag), greaterThan(0));
      final result = RecommendationService.listForTaste([
        '축구',
      ], [soccerMag, interiorMag]);
      expect(result.kind, RecommendationMatchKind.direct);
    });
  });

  group('선반은 취향 칩마다 실제로 맞는 매거진을 보장한다', () {
    // '등산'의 유일 매거진. 점수가 낮아 동점 정렬에서 밀리기 쉽다.
    const hiking = Magazine(
      title: 'HOLD',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['클라이밍', '등산', '스포츠웨어'],
    );
    const baseball = Magazine(
      title: 'EXTRA INNING',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['야구', '스포츠 관람', '스포츠 여행'],
    );
    // 취향 여러 개를 동시에 만족해 점수가 높은 매거진들
    const bakery = Magazine(
      title: 'Bakery Letters',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['베이커리', '디저트', '카페'],
    );
    const coffee = Magazine(
      title: 'Drift',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['카페', '커피', '도시 여행'],
    );
    const dessert = Magazine(
      title: 'The Gourmand',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['디저트', '브런치', '현대미술'],
    );
    const wine = Magazine(
      title: 'CELLAR',
      tagline: '',
      issue: '',
      coverUrl: '',
      tags: ['와인', '파인다이닝', '미식 여행'],
    );
    final catalog = [bakery, coffee, dessert, wine, hiking, baseball];
    const taste = ['커피', '베이커리', '와인', '등산'];

    test('점수가 낮아도 취향 태그의 유일 매거진은 선반에 오른다', () {
      final shelf = RecommendationService.buildInitialShelf(
        taste,
        catalog,
        daySeed: 1,
      );
      expect(
        shelf.map((m) => m.title),
        containsAll(['HOLD', 'CELLAR']),
        reason: '등산·와인 칩을 눌렀을 때 갈 곳이 선반에 있어야 함',
      );
    });

    test("'등산' 칩은 야구가 아니라 등산 매거진을 가리킨다", () {
      final shelf = RecommendationService.buildInitialShelf(
        taste,
        catalog,
        daySeed: 1,
      );
      final index = RecommendationService.focusIndexForTaste(shelf, '등산');
      expect(index, isNotNull);
      expect(shelf[index!].title, 'HOLD');
    });

    test('선반에 그 취향의 매거진이 없으면 엉뚱한 곳으로 튀지 않는다 (null)', () {
      final index = RecommendationService.focusIndexForTaste([baseball], '등산');
      expect(index, isNull);
    });

    test('폴백은 큐레이트된 이웃(자연·산책)을 형제(야구)보다 우선한다', () {
      const nature = Magazine(
        title: 'Run Log',
        tagline: '',
        issue: '',
        coverUrl: '',
        tags: ['러닝', '웰니스', '자연'],
      );
      expect(
        RecommendationService.fallbackScore(['등산'], nature),
        greaterThan(RecommendationService.fallbackScore(['등산'], baseball)),
      );
    });
  });
}
