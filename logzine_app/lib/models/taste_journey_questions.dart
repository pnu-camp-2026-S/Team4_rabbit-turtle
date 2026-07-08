/// 취향 탐색 여정의 질문 풀.
/// 사용자는 질문마다 사진 한 장으로 답하고, 질문 텍스트는
/// [TastePhoto.question]으로 Gemini 분석에 맥락으로 전달된다.
library;

/// 전체 질문 풀. 0번은 여정의 시작 질문으로 항상 고정.
const List<String> kTasteJourneyQuestionPool = [
  '가장 행복했던 순간은 언제였나요?',
  '이번 달 주말, 기억에 남는 장면이 있나요?',
  '갤러리에서 가장 눈에 띄는 사진은 무엇인가요?',
  '작년 이맘때, 당신은 어디에 있었나요?',
  '괜히 자꾸 다시 보게 되는 사진이 있나요?',
  '누군가에게 보여주고 싶었던 풍경이 있나요?',
  '혼자만의 시간을 보낸 장소가 있나요?',
  '최근 당신을 웃게 만든 장면은 무엇인가요?',
  '오래 머물고 싶었던 공간이 있었나요?',
  '지금 계절을 가장 잘 담은 사진 한 장은요?',
];

/// 오늘의 여정 질문 [count]개.
/// 첫 질문은 고정, 나머지는 날짜 기반 로테이션(큐레이터 문구와 동일 패턴) —
/// 같은 날에는 항상 같은 질문 구성이라 데모와 팀 테스트가 재현 가능하다.
List<String> pickJourneyQuestions({int count = 5, DateTime? now}) {
  final date = now ?? DateTime.now();
  final dayIndex = date.difference(DateTime(date.year)).inDays;
  final rest = kTasteJourneyQuestionPool.sublist(1);
  final rotated = [
    for (var i = 0; i < rest.length; i++) rest[(dayIndex + i) % rest.length],
  ];
  final picked = count.clamp(1, kTasteJourneyQuestionPool.length);
  return [kTasteJourneyQuestionPool.first, ...rotated.take(picked - 1)];
}
