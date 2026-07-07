/// 온보딩 태그 어휘 — UI(태그 화면)와 AI 분석기가 공유하는 단일 출처.
const Map<String, List<String>> kMoodVocab = {
  'Mood': ['Calm', 'Warm', 'Minimal', 'Sensory'],
  'Space': ['Interior', 'Studio', 'Living', 'Wood'],
  'Style': ['Editorial', 'Natural light', 'Objects', 'Books'],
};

/// kMoodVocab의 모든 태그를 평탄화한 집합.
final Set<String> kAllMoodTags = {
  for (final tags in kMoodVocab.values) ...tags,
};

/// AI 사진 무드 분석 결과.
class MoodAnalysis {
  const MoodAnalysis({
    required this.tags,
    required this.suggested,
    required this.summary,
  });

  /// kMoodVocab 어휘 중에서 사진과 어울리는 것으로 선택된 태그들.
  final Set<String> tags;

  /// 어휘 밖에서 AI가 자유롭게 제안한 키워드 (최대 3개, 예: 'Warm wood').
  final List<String> suggested;

  /// 취향 한 줄 요약 (영문, 예: 'A calm editorial space with warm materials.').
  final String summary;
}
