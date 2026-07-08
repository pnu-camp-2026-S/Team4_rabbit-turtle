import 'package:flutter_test/flutter_test.dart';
import 'package:logzine_app/models/taste_journey_questions.dart';

void main() {
  group('pickJourneyQuestions', () {
    test('기본 5개, 첫 질문은 여정 시작 질문으로 고정', () {
      final questions = pickJourneyQuestions(now: DateTime(2026, 7, 9));
      expect(questions, hasLength(5));
      expect(questions.first, kTasteJourneyQuestionPool.first);
    });

    test('중복 질문이 없다', () {
      final questions = pickJourneyQuestions(now: DateTime(2026, 7, 9));
      expect(questions.toSet(), hasLength(questions.length));
    });

    test('같은 날에는 항상 같은 구성 (데모 재현성)', () {
      final a = pickJourneyQuestions(now: DateTime(2026, 7, 9, 9));
      final b = pickJourneyQuestions(now: DateTime(2026, 7, 9, 21));
      expect(a, equals(b));
    });

    test('날짜가 다르면 뒤 질문들이 로테이션된다', () {
      final a = pickJourneyQuestions(now: DateTime(2026, 7, 9));
      final b = pickJourneyQuestions(now: DateTime(2026, 7, 10));
      expect(a.sublist(1), isNot(equals(b.sublist(1))));
      expect(a.first, equals(b.first));
    });

    test('모든 질문은 풀에서만 나온다', () {
      final questions = pickJourneyQuestions(now: DateTime(2026, 7, 9));
      for (final q in questions) {
        expect(kTasteJourneyQuestionPool, contains(q));
      }
    });
  });
}
