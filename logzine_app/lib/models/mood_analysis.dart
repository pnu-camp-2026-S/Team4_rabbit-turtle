import 'dart:typed_data';

import 'ui_keyword_vocabulary.dart';

/// 온보딩 태그 어휘 — UI keyword vocabulary만 사용한다.
const Map<String, List<String>> kMoodVocab = UiKeywordVocabulary.groups;

/// kMoodVocab의 모든 태그를 평탄화한 집합.
final Set<String> kAllMoodTags = UiKeywordVocabulary.allowed;

/// 업로드 화면 → 태그 화면으로 넘기는 온보딩 데이터 묶음.
class MoodTagsArgs {
  const MoodTagsArgs({
    this.analysis,
    this.photoBytes = const [],
    this.photoUrls = const [],
  });

  /// AI 분석 결과 (실패/미사용이면 null → 데모 폴백).
  final MoodAnalysis? analysis;

  /// 갤러리에서 첨부한 사진들 (bytes).
  final List<Uint8List> photoBytes;

  /// 데모 프리셋 사진 URL들.
  final List<String> photoUrls;
}

/// AI 사진 무드 분석 결과.
class MoodAnalysis {
  const MoodAnalysis({
    required this.tags,
    required this.suggested,
    required this.summary,
  });

  /// kMoodVocab 어휘 중에서 사진과 어울리는 것으로 선택된 태그들.
  final Set<String> tags;

  /// 보조 후보. 화면에 노출할 때는 UI keyword vocabulary 안의 값만 사용한다.
  final List<String> suggested;

  /// 취향 한 줄 요약 (영문, 예: 'A calm editorial space with warm materials.').
  final String summary;
}
