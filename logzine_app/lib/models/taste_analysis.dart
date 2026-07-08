import 'dart:convert';
import 'dart:typed_data';

enum TasteKeywordType {
  object,
  placeType,
  activity,
  mood,
  interest,
  context,
  preference,
  negativeSignal,
}

enum TasteKeywordStatus { draft, needsConfirmation, confirmed, removed }

class TastePhoto {
  const TastePhoto({
    required this.name,
    required this.bytes,
    required this.mimeType,
    this.question = '',
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  /// 취향 여정에서 이 사진이 답한 질문 (분석 시 Gemini에 맥락으로 전달).
  final String question;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

class TasteKeyword {
  const TasteKeyword({
    required this.label,
    required this.type,
    required this.confidence,
    required this.evidence,
    this.category,
    this.mappedConcepts = const [],
    this.status = TasteKeywordStatus.draft,
  });

  final String label;
  final TasteKeywordType type;
  final double confidence;
  final String evidence;
  final String? category;
  final List<String> mappedConcepts;
  final TasteKeywordStatus status;

  TasteKeyword copyWith({TasteKeywordStatus? status}) {
    return TasteKeyword(
      label: label,
      type: type,
      confidence: confidence,
      evidence: evidence,
      category: category,
      mappedConcepts: mappedConcepts,
      status: status ?? this.status,
    );
  }
}

class TasteAnalysisResult {
  const TasteAnalysisResult({
    required this.photos,
    required this.summary,
    required this.keywords,
    required this.recommendedQuestion,
    required this.privacyNotes,
  });

  factory TasteAnalysisResult.empty() {
    return const TasteAnalysisResult(
      photos: [],
      summary: '사진을 추가하면 관심사 후보를 분석할 수 있어요.',
      keywords: [],
      recommendedQuestion: '이 사진에서 가장 중요했던 건 무엇인가요?',
      privacyNotes: ['사진이 선택되기 전에는 분석을 실행하지 않음'],
    );
  }

  final List<TastePhoto> photos;
  final String summary;
  final List<TasteKeyword> keywords;
  final String recommendedQuestion;
  final List<String> privacyNotes;

  List<TasteKeyword> get primaryKeywords => keywords
      .where((keyword) => keyword.status == TasteKeywordStatus.draft)
      .take(3)
      .toList();

  List<TasteKeyword> get secondaryKeywords => keywords
      .where((keyword) => keyword.status == TasteKeywordStatus.draft)
      .skip(3)
      .take(8)
      .toList();

  List<TasteKeyword> get uncertainKeywords => keywords
      .where(
        (keyword) => keyword.status == TasteKeywordStatus.needsConfirmation,
      )
      .take(2)
      .toList();
}

class TasteProfileDraft {
  const TasteProfileDraft({
    required this.photoTags,
    required this.confirmedTags,
    required this.preferenceProfile,
    required this.summary,
    required this.photos,
    this.feedback = '',
  });

  final List<TasteKeyword> photoTags;
  final List<TasteKeyword> confirmedTags;
  final List<TasteKeyword> preferenceProfile;
  final String summary;
  final List<TastePhoto> photos;
  final String feedback;

  List<String> get displayTags =>
      preferenceProfile.map((keyword) => keyword.label).take(6).toList();
}

