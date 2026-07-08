import 'package:flutter_test/flutter_test.dart';
import 'package:logzine_app/models/taste_analysis.dart';

TasteKeyword _keyword(String label) => TasteKeyword(
  label: label,
  type: TasteKeywordType.preference,
  confidence: 0.9,
  evidence: 'test',
  status: TasteKeywordStatus.draft,
);

void main() {
  group('PhotoTasteAnalyzer.refineProfile fallback', () {
    test('Gemini가 없어도 줄글의 선호와 비선호를 반영한다', () async {
      final analysis = TasteAnalysisResult(
        photos: const [],
        summary: 'test',
        keywords: [_keyword('카페'), _keyword('자연')],
        recommendedQuestion: 'test',
        privacyNotes: const [],
      );

      final profile = await PhotoTasteAnalyzer.refineProfile(
        analysis: analysis,
        confirmedLabels: {'카페', '자연'},
        feedback: 'I also like playing soccer. 자연은 싫어.',
      );

      expect(profile.displayTags, contains('축구'));
      expect(profile.displayTags, contains('카페'));
      expect(profile.displayTags, isNot(contains('자연')));
      expect(
        profile.photoTags
            .singleWhere((keyword) => keyword.label == '자연')
            .status,
        TasteKeywordStatus.removed,
      );
    });

    test('A보다는 B 피드백을 B 중심 키워드로 보정한다', () async {
      final analysis = TasteAnalysisResult(
        photos: const [],
        summary: 'test',
        keywords: [_keyword('러닝'), _keyword('도시 여행')],
        recommendedQuestion: 'test',
        privacyNotes: const [],
      );

      final profile = await PhotoTasteAnalyzer.refineProfile(
        analysis: analysis,
        confirmedLabels: {'러닝'},
        feedback: '나는 활동적인 것보다는 조용한분위기를 좋아해. 여행도 좋아하긴해.',
      );

      expect(profile.displayTags, contains('조용한 휴식'));
      expect(profile.displayTags, contains('도시 여행'));
      expect(profile.displayTags, isNot(contains('러닝')));
    });
  });
}
