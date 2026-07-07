import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

class TasteKeyword {
  const TasteKeyword({
    required this.label,
    required this.type,
    required this.confidence,
    required this.evidence,
    this.status = TasteKeywordStatus.draft,
  });

  final String label;
  final TasteKeywordType type;
  final double confidence;
  final String evidence;
  final TasteKeywordStatus status;

  TasteKeyword copyWith({TasteKeywordStatus? status}) {
    return TasteKeyword(
      label: label,
      type: type,
      confidence: confidence,
      evidence: evidence,
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
      .take(5)
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

class PhotoTasteAnalyzer {
  const PhotoTasteAnalyzer._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const String _fallbackModel = 'gemini-flash-latest';
  static const int _maxAttemptsPerModel = 3;

  static Future<TasteAnalysisResult> analyze(List<TastePhoto> photos) async {
    if (photos.isEmpty) {
      throw const TasteAnalysisException('분석할 사진을 먼저 추가해주세요.');
    }
    if (_apiKey.isEmpty) {
      throw const TasteAnalysisException(
        'GEMINI_API_KEY가 없습니다. 실행할 때 --dart-define=GEMINI_API_KEY=... 를 추가해주세요.',
      );
    }

    http.Response? lastResponse;
    Object? lastError;

    for (final model in _candidateModels) {
      for (var attempt = 0; attempt < _maxAttemptsPerModel; attempt++) {
        try {
          final response = await _requestAnalysis(model, photos);
          lastResponse = response;

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return _resultFromResponse(response, photos);
          }

          if (!_shouldRetryResponse(response)) {
            throw TasteAnalysisException(_friendlyHttpError(response));
          }
        } on TasteAnalysisException {
          rethrow;
        } on TimeoutException catch (error) {
          lastError = error;
        } on http.ClientException catch (error) {
          lastError = error;
        }

        if (attempt < _maxAttemptsPerModel - 1) {
          await Future<void>.delayed(_retryDelay(attempt));
        }
      }
    }

    if (lastResponse != null) {
      throw TasteAnalysisException(_friendlyHttpError(lastResponse));
    }
    throw TasteAnalysisException(
      'Gemini 분석 요청이 일시적으로 불안정해요. 잠시 뒤 다시 시도해주세요. ${lastError ?? ''}',
    );
  }

  static List<String> get _candidateModels {
    if (_model == _fallbackModel) return const [_model];
    return const [_model, _fallbackModel];
  }

  static Duration _retryDelay(int attempt) {
    return Duration(milliseconds: 900 * (1 << attempt));
  }

  static Future<http.Response> _requestAnalysis(
    String model,
    List<TastePhoto> photos,
  ) {
    return http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          ),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'text':
                        '$_prompt\n\nReturn only valid JSON that matches this schema:\n${jsonEncode(_schema)}',
                  },
                  for (final photo in photos)
                    {
                      'inlineData': {
                        'mimeType': photo.mimeType,
                        'data': base64Encode(photo.bytes),
                      },
                    },
                ],
              },
            ],
            'generationConfig': {'responseMimeType': 'application/json'},
          }),
        )
        .timeout(const Duration(seconds: 35));
  }

  static TasteAnalysisResult _resultFromResponse(
    http.Response response,
    List<TastePhoto> photos,
  ) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw const TasteAnalysisException('Gemini 응답에서 분석 JSON을 찾지 못했어요.');
    }

    final data = jsonDecode(outputText) as Map<String, dynamic>;
    return TasteAnalysisResult(
      photos: photos,
      summary: data['summary'] as String,
      keywords: [
        for (final item in data['keywords'] as List<dynamic>)
          _keywordFromJson(item as Map<String, dynamic>),
      ],
      recommendedQuestion: data['recommended_question'] as String,
      privacyNotes: [
        for (final note in data['privacy_notes'] as List<dynamic>)
          note as String,
      ],
    );
  }

  static bool _shouldRetryResponse(http.Response response) {
    if (response.statusCode == 408 ||
        response.statusCode == 429 ||
        response.statusCode == 500 ||
        response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504) {
      return true;
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is! Map<String, dynamic>) return false;
      final message = (error['message'] as String? ?? '').toLowerCase();
      final status = (error['status'] as String? ?? '').toLowerCase();
      return status.contains('unavailable') ||
          status.contains('resource_exhausted') ||
          message.contains('high demand') ||
          message.contains('overloaded') ||
          message.contains('temporarily unavailable');
    } catch (_) {
      return false;
    }
  }

  static TasteProfileDraft buildProfile({
    required TasteAnalysisResult analysis,
    required Set<String> confirmedLabels,
    String feedback = '',
  }) {
    final trimmedFeedback = feedback.trim();
    final removedLabels = _feedbackRemovedLabels(
      trimmedFeedback,
      analysis.keywords,
    );
    final confirmed = [
      ...analysis.keywords
          .where(
            (keyword) =>
                confirmedLabels.contains(keyword.label) &&
                !removedLabels.contains(keyword.label),
          )
          .map(
            (keyword) => keyword.copyWith(status: TasteKeywordStatus.confirmed),
          ),
    ];

    final photoTags = analysis.keywords
        .map(
          (keyword) => removedLabels.contains(keyword.label)
              ? keyword.copyWith(status: TasteKeywordStatus.removed)
              : keyword,
        )
        .toList();

    final preferences = confirmed.where((keyword) {
      return keyword.type == TasteKeywordType.mood ||
          keyword.type == TasteKeywordType.interest ||
          keyword.type == TasteKeywordType.context ||
          keyword.type == TasteKeywordType.preference ||
          keyword.confidence >= 0.85;
    }).toList();

    return TasteProfileDraft(
      photoTags: photoTags,
      confirmedTags: confirmed,
      preferenceProfile: preferences.isEmpty ? confirmed : preferences,
      summary: _profileSummary(preferences.isEmpty ? confirmed : preferences),
      photos: analysis.photos,
      feedback: trimmedFeedback,
    );
  }

  static Future<TasteProfileDraft> refineProfile({
    required TasteAnalysisResult analysis,
    required Set<String> confirmedLabels,
    required String feedback,
  }) async {
    final fallback = buildProfile(
      analysis: analysis,
      confirmedLabels: confirmedLabels,
      feedback: '',
    );
    final trimmedFeedback = feedback.trim();
    if (_apiKey.isEmpty || trimmedFeedback.isEmpty) return fallback;

    final aiKeywords = [for (final keyword in analysis.keywords) keyword.label];
    final selectedKeywords = [
      for (final keyword in analysis.keywords)
        if (confirmedLabels.contains(keyword.label)) keyword.label,
    ];
    final deselectedKeywords = [
      for (final keyword in analysis.keywords)
        if (!confirmedLabels.contains(keyword.label)) keyword.label,
    ];

    try {
      final response = await _requestKeywordRefinement(
        aiKeywords: aiKeywords,
        selectedKeywords: selectedKeywords,
        deselectedKeywords: deselectedKeywords,
        feedback: trimmedFeedback,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback;
      }

      final outputText = _extractOutputText(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (outputText == null || outputText.trim().isEmpty) return fallback;

      final data = jsonDecode(outputText) as Map<String, dynamic>;
      final excludedLabels = _excludedLabelsFromJson(data);
      final refinedKeywords = _cleanProfileKeywords([
        ..._refinedKeywordsFromJson(data),
      ], excludedLabels: excludedLabels);
      if (refinedKeywords.isEmpty) return fallback;

      final photoTags = analysis.keywords.map((keyword) {
        return excludedLabels.any(
              (label) => _labelsOverlap(label, keyword.label),
            )
            ? keyword.copyWith(status: TasteKeywordStatus.removed)
            : keyword;
      }).toList();

      return TasteProfileDraft(
        photoTags: photoTags,
        confirmedTags: refinedKeywords,
        preferenceProfile: refinedKeywords,
        summary: _profileSummary(refinedKeywords),
        photos: analysis.photos,
        feedback: trimmedFeedback,
      );
    } catch (_) {
      return fallback;
    }
  }

  static Future<http.Response> _requestKeywordRefinement({
    required List<String> aiKeywords,
    required List<String> selectedKeywords,
    required List<String> deselectedKeywords,
    required String feedback,
  }) {
    final input = {
      'ai_keywords': aiKeywords,
      'selected_keywords': selectedKeywords,
      'deselected_keywords': deselectedKeywords,
      'free_text_feedback': feedback,
    };

    return http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_fallbackModel:generateContent',
          ),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'text':
                        '$_refinerPrompt\n\nInput JSON:\n${jsonEncode(input)}\n\nReturn only valid JSON that matches this schema:\n${jsonEncode(_refinerSchema)}',
                  },
                ],
              },
            ],
            'generationConfig': {'responseMimeType': 'application/json'},
          }),
        )
        .timeout(const Duration(seconds: 25));
  }

  static List<TasteKeyword> _refinedKeywordsFromJson(
    Map<String, dynamic> json,
  ) {
    final displayKeywords = _displayKeywordsFromJson(json);
    if (displayKeywords.isNotEmpty) {
      return [
        for (final label in displayKeywords)
          TasteKeyword(
            label: label,
            type: TasteKeywordType.preference,
            confidence: 0.95,
            evidence: '사용자 피드백 정제',
            status: TasteKeywordStatus.confirmed,
          ),
      ];
    }

    final items = json['final_keywords'];
    if (items is! List<dynamic>) return const <TasteKeyword>[];

    final keywords = <TasteKeyword>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final label = _normalizeFinalLabel(item['label'] as String? ?? '');
      if (label == null || label.isEmpty) continue;
      if (keywords.any((keyword) => keyword.label == label)) continue;
      keywords.add(
        TasteKeyword(
          label: label,
          type: _typeFromApi(item['type'] as String? ?? 'preference'),
          confidence: ((item['confidence'] as num?) ?? 0.9).toDouble(),
          evidence: item['reason'] as String? ?? '사용자 피드백 정제',
          status: TasteKeywordStatus.confirmed,
        ),
      );
      if (keywords.length >= 8) break;
    }
    return keywords;
  }

  static List<String> _displayKeywordsFromJson(Map<String, dynamic> json) {
    final items = json['display_keywords'];
    if (items is! List<dynamic>) return const <String>[];
    final labels = <String>[];
    for (final item in items) {
      if (item is! String) continue;
      final label = _normalizeFinalLabel(item);
      if (label == null || labels.contains(label)) continue;
      labels.add(label);
      if (labels.length >= 8) break;
    }
    return labels;
  }

  static Set<String> _excludedLabelsFromJson(Map<String, dynamic> json) {
    final items = json['excluded_keywords'];
    if (items is! List<dynamic>) return const <String>{};
    return {
      for (final item in items)
        if (item is Map<String, dynamic> &&
            item['label'] is String &&
            (item['label'] as String).trim().isNotEmpty)
          (item['label'] as String).trim(),
    };
  }

  static Set<String> _feedbackRemovedLabels(
    String feedback,
    List<TasteKeyword> keywords,
  ) {
    if (feedback.isEmpty) return const <String>{};
    final lower = feedback.toLowerCase();
    final removed = <String>{};
    final negativeSubjects = _negativeSubjects(feedback);
    for (final keyword in keywords) {
      final label = keyword.label;
      final labelLower = label.toLowerCase();
      final mentionsLabel =
          lower.contains(labelLower) || feedback.contains(label);
      if (!mentionsLabel) continue;
      final negativeNearLabel = RegExp(
        '${RegExp.escape(label)}.{0,12}(아니|싫|제외|빼|삭제|별로|아님)',
        caseSensitive: false,
      ).hasMatch(feedback);
      final negativeBeforeLabel = RegExp(
        '(아니|싫|제외|빼|삭제|별로).{0,12}${RegExp.escape(label)}',
        caseSensitive: false,
      ).hasMatch(feedback);
      if (negativeNearLabel || negativeBeforeLabel) {
        removed.add(label);
        continue;
      }
      for (final subject in negativeSubjects) {
        if (_labelsOverlap(label, subject)) {
          removed.add(label);
          break;
        }
      }
    }
    return removed;
  }

  static Set<String> _negativeSubjects(String feedback) {
    final subjects = <String>{};
    final patterns = [
      RegExp(r'([가-힣A-Za-z0-9/·\s]{2,18})(?:보다는|보다\s+|말고)'),
      RegExp(
        r'([가-힣A-Za-z0-9/·\s]{2,18})(?:은|는|이|가)?\s*(?:안\s*좋아|싫어|별로|관심\s*없|제외|빼줘)',
      ),
      RegExp(
        r"(?:don't like|do not like|dislike|hate|not into|exclude|remove|less)\s+([a-zA-Z][a-zA-Z\s/&-]{1,28})",
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(feedback)) {
        final value = match.group(1)?.trim();
        if (value == null || value.isEmpty) continue;
        final normalized = _normalizeFinalLabel(
          _normalizeEnglishKeyword(value),
        );
        if (normalized != null) subjects.add(normalized);
      }
    }
    return subjects;
  }

  static List<TasteKeyword> _cleanProfileKeywords(
    List<TasteKeyword> keywords, {
    required Set<String> excludedLabels,
  }) {
    final cleaned = <TasteKeyword>[];
    for (final keyword in keywords) {
      final label = _normalizeFinalLabel(keyword.label);
      if (label == null) continue;
      final excluded = excludedLabels.any(
        (excludedLabel) => _labelsOverlap(label, excludedLabel),
      );
      if (excluded) continue;
      if (cleaned.any((item) => _labelsOverlap(item.label, label))) continue;
      cleaned.add(
        TasteKeyword(
          label: label,
          type: keyword.type,
          confidence: keyword.confidence,
          evidence: keyword.evidence,
          status: keyword.status,
        ),
      );
      if (cleaned.length >= 6) break;
    }
    return cleaned;
  }

  static bool _labelsOverlap(String left, String right) {
    final leftParts = left
        .split(RegExp(r'[/·\s]+'))
        .where((part) => part.length >= 2)
        .toSet();
    final rightParts = right
        .split(RegExp(r'[/·\s]+'))
        .where((part) => part.length >= 2)
        .toSet();
    return left.contains(right) ||
        right.contains(left) ||
        leftParts.intersection(rightParts).isNotEmpty;
  }

  static String _normalizeEnglishKeyword(String value) {
    final lower = value.toLowerCase().trim();
    return switch (lower) {
      'soccer' || 'football' => '축구',
      'playing soccer' || 'playing football' => '축구하기',
      'baking' => '베이킹',
      'coffee' => '커피',
      'cafe' || 'cafes' => '카페',
      'reading' || 'books' => '독서',
      'art' => '예술',
      'gallery' || 'galleries' => '갤러리',
      'exhibition' || 'exhibitions' => '전시',
      _ =>
        value
            .split(RegExp(r'\s+'))
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' '),
    };
  }

  static String? _normalizeFinalLabel(String value) {
    var label = value.trim();
    if (label.isEmpty) return null;
    if (_looksLikeRawOrNegativeFeedback(label)) return null;

    final mapped = _taxonomyLabelFor(label);
    if (mapped != null) return mapped;

    label = label
        .replaceAll(
          RegExp(
            r'\bI\s+(also\s+)?(like|love|prefer|want)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r"\bI'm into\b", caseSensitive: false), '')
        .replaceAll(RegExp(r'\bnot into\b', caseSensitive: false), '')
        .replaceAll(RegExp(r"\bdon'?t like\b", caseSensitive: false), '')
        .replaceAll(RegExp(r'\bdislike\b|\bhate\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(나는|제가|내가)\s*'), '')
        .replaceAll(RegExp(r'^((것|거)(보다는|보다)|사실|그리고|또한|또)\s*'), '')
        .replaceAll(RegExp(r'.*(?:보다는|보다\s+|말고)\s*'), '')
        .replaceAll(
          RegExp(r'(좋아하긴\s*해|좋아해|좋아하고|좋습니다|좋아|관심 있어|관심있어|원해|선호해|하고 싶어).*$'),
          '',
        )
        .replaceAll(RegExp(r'(싫어|안 좋아|관심 없어|별로|아니야).*$'), '')
        .trim();

    final remapped = _taxonomyLabelFor(label);
    if (remapped != null) return remapped;

    label = switch (label) {
      '도시탐험' => '도시 탐험',
      'playing soccer' || 'Playing Soccer' => '축구하기',
      'soccer' || 'Soccer' || 'football' || 'Football' => '축구',
      'outdoor' || 'Outdoor' || 'outdoors' || 'Outdoors' => '아웃도어',
      _ => label,
    };

    label = label.replaceAll(RegExp(r'\s+'), ' ').trim();
    label = label.replaceAll(RegExp(r'(을|를|은|는|이|가|하고|안|도)$'), '').trim();

    final finalMapped = _taxonomyLabelFor(label);
    if (finalMapped != null) return finalMapped;

    if (label.length < 2 || label.length > 16) return null;
    if (label.contains('...') || label.contains('…')) return null;
    if (label.contains('보다는') || label.contains('좋아하긴')) return null;
    if (RegExp(
      r"나는|제가|내가|I like|I\b|I'm",
      caseSensitive: false,
    ).hasMatch(label)) {
      return null;
    }
    if (RegExp(
      r"싫어|안 좋아|관심 없어|무서워|두려워|겁나|not into|don'?t like|afraid|scared",
      caseSensitive: false,
    ).hasMatch(label)) {
      return null;
    }
    if (RegExp(r'(을|를|은|는|이|가|하고|안|도)$').hasMatch(label)) {
      return null;
    }
    return label;
  }

  static bool _looksLikeRawOrNegativeFeedback(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^(나|나는|내가|제가)').hasMatch(compact)) return true;
    if (RegExp(r'(싫어|안좋아|관심없어|별로|무서워|두려워|겁나)').hasMatch(compact)) {
      return true;
    }
    if (RegExp(
      r"\b(i\s+|i'm|i like|not into|don't like|do not like|afraid|scared)\b",
      caseSensitive: false,
    ).hasMatch(value)) {
      return true;
    }
    return false;
  }

  static String? _taxonomyLabelFor(String value) {
    final compact = value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[.!?。！？,]'), '');
    if (compact.isEmpty) return null;

    if (compact.contains('조용한') && compact.contains('분위기')) {
      return '조용한 분위기';
    }
    if (compact.contains('조용한') &&
        (compact.contains('휴식') || compact.contains('쉬'))) {
      return '조용한 휴식';
    }
    if (compact.contains('차분한') || compact.contains('잔잔한')) {
      return '차분한 분위기';
    }
    if (compact.contains('여행')) return '여행';
    if (compact.contains('활동적') || compact.contains('액티브')) {
      return '활동적인 취향';
    }
    if (compact.contains('아웃도어') || compact.contains('야외')) {
      return '자연/아웃도어';
    }
    if (compact.contains('자연') || compact.contains('풍경')) {
      return '자연 풍경';
    }
    if (compact.contains('공부') ||
        compact.contains('업무') ||
        compact.contains('작업')) {
      return '공부/작업';
    }
    if (compact.contains('문화') && compact.contains('건축')) {
      return '문화/건축';
    }
    if (compact.contains('건축') || compact.contains('디자인')) {
      return '건축/디자인';
    }
    if (compact.contains('전시') ||
        compact.contains('갤러리') ||
        compact.contains('예술')) {
      return '전시/예술';
    }
    if (compact.contains('카페') && compact.contains('커피')) {
      return '카페/커피';
    }
    if (compact.contains('카페')) return '카페';
    if (compact.contains('커피')) return '커피';
    if (compact.contains('책') || compact.contains('독서')) return '독서';
    if (compact.contains('산책')) return '산책';
    return null;
  }

  static TasteKeyword _keywordFromJson(Map<String, dynamic> json) {
    return TasteKeyword(
      label: json['label'] as String,
      type: _typeFromApi(json['type'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      evidence: json['evidence'] as String,
      status: _statusFromApi(json['status'] as String),
    );
  }

  static TasteKeywordType _typeFromApi(String type) {
    return switch (type) {
      'object' => TasteKeywordType.object,
      'place_type' => TasteKeywordType.placeType,
      'activity' => TasteKeywordType.activity,
      'mood' => TasteKeywordType.mood,
      'interest' => TasteKeywordType.interest,
      'content' => TasteKeywordType.interest,
      'context' => TasteKeywordType.context,
      'preference' => TasteKeywordType.preference,
      'negative_signal' => TasteKeywordType.negativeSignal,
      _ => TasteKeywordType.interest,
    };
  }

  static TasteKeywordStatus _statusFromApi(String status) {
    return switch (status) {
      'draft' => TasteKeywordStatus.draft,
      'needs_confirmation' => TasteKeywordStatus.needsConfirmation,
      'confirmed' => TasteKeywordStatus.confirmed,
      'removed' => TasteKeywordStatus.removed,
      _ => TasteKeywordStatus.draft,
    };
  }

  static String? _extractOutputText(Map<String, dynamic> response) {
    final helperText = response['output_text'];
    if (helperText is String) return helperText;

    final text = response['text'];
    if (text is String) return text;

    final output = response['output'];
    final outputText = _extractTextFromItems(output);
    if (outputText != null) return outputText;

    final candidates = response['candidates'];
    if (candidates is List<dynamic>) {
      for (final candidate in candidates) {
        if (candidate is! Map<String, dynamic>) continue;
        final content = candidate['content'];
        if (content is! Map<String, dynamic>) continue;
        final candidateText = _extractTextFromItems(content['parts']);
        if (candidateText != null) return candidateText;
      }
    }
    return null;
  }

  static String? _extractTextFromItems(dynamic items) {
    if (items is! List<dynamic>) return null;
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final directText = item['text'];
      if (directText is String) return directText;

      final content = item['content'];
      final contentText = _extractTextFromItems(content);
      if (contentText != null) return contentText;

      final parts = item['parts'];
      final partsText = _extractTextFromItems(parts);
      if (partsText != null) return partsText;
    }
    return null;
  }

  static String _friendlyHttpError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        final status = error['status'];
        if (status == 'RESOURCE_EXHAUSTED' || response.statusCode == 429) {
          return 'Gemini API 할당량 또는 요청 한도에 걸렸어요. Google AI Studio/Google Cloud에서 quota와 billing 상태를 확인한 뒤 다시 시도해주세요.';
        }
        if (status == 'UNAVAILABLE' ||
            response.statusCode == 503 ||
            (message is String &&
                message.toLowerCase().contains('high demand'))) {
          return 'Gemini 서버가 일시적으로 혼잡해요. 자동 재시도를 했지만 실패했습니다. 잠시 뒤 다시 분석해주세요.';
        }
        if (response.statusCode == 400) {
          return 'Gemini 분석 요청 형식이 맞지 않아요. 모델명과 이미지 형식을 확인해주세요.';
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          return 'Gemini API 키가 유효하지 않거나 권한이 없어요. 저장된 GEMINI_API_KEY를 확인해주세요.';
        }
        if (message is String && message.isNotEmpty) {
          return 'Gemini 분석 요청 실패 (${response.statusCode}): $message';
        }
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'Gemini 분석 요청 실패 (${response.statusCode}). 잠시 뒤 다시 시도해주세요.';
  }

  static String _profileSummary(List<TasteKeyword> keywords) {
    final labels = keywords.map((keyword) => keyword.label).take(3).toList();
    if (labels.isEmpty) {
      return '사진에서 찾은 관심사 후보를 더 확인해볼 수 있어요.';
    }
    return '${labels.join(', ')} 중심의 조용한 콘텐츠 취향 후보예요.';
  }
}

class TasteAnalysisException implements Exception {
  const TasteAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String _prompt = '''
Use the Photo Taste Analyzer skill to analyze the user photos into confirmable taste keywords for LOGZINE, an editorial magazine recommendation app.

Rules:
- Do not list every visible object. Keep only recommendation-relevant taste signals.
- Ignore accidental background noise, passersby, small clutter, and sensitive personal attributes.
- Do not infer identity, exact location, home/workplace proximity, wealth, health, religion, politics, relationship, age, gender, or ethnicity.
- Prefer experience-level meanings over raw object labels.
- Mark uncertain context as "needs_confirmation".
- Return 3 representative draft keywords, 3-5 secondary draft keywords, and at most 2 needs_confirmation keywords.
- Use Korean labels when natural for the user's likely UI, but short English labels are allowed for established editorial moods.
- The result is a draft the user can edit, not a final diagnosis.

Keyword types:
object, place_type, activity, mood, interest, context, preference, negative_signal.

Taxonomy examples:
- culture_art: history/tradition, architecture/design, museum/gallery, craft/object
- travel_place: slow travel, local walk, tourist site, hidden place, scenic spot
- lifestyle: quiet rest, daily leisure, study/work, routine record, aesthetic collection
- food_drink: coffee, tea, dessert, bakery, casual dining
- nature_outdoor: walk, park, waterfront, forest, seasonal view
- urban_local: neighborhood, bookstore, market, street scene, local brand
''';

const String _refinerPrompt = '''
Use the Taste Keyword Refiner skill to merge photo-analysis keywords, selected chips, deselected chips, and free-text feedback into final recommendation keywords for LOGZINE.

Rules:
- You are the only component that decides final user taste keywords from free_text_feedback. The app will only render your display_keywords/final_keywords.
- Do semantic interpretation, not word matching. Understand whether a sentence means preference, dislike, fear/avoidance, correction, context, or explanation.
- User free-text feedback always has higher priority than AI guesses and chip state.
- If the user explicitly dislikes or negates a keyword, remove it from final_keywords and include it in excluded_keywords.
- If the user says they fear or avoid something, do not make that phrase a keyword. Convert it into excluded_keywords or downweighted_keywords for the relevant taste category.
- If the user adds a new interest in Korean or English, normalize it into short Korean recommendation keywords.
- Snap free-text meanings to the closest recommendation taxonomy label when possible: 여행, 조용한 분위기, 조용한 휴식, 카페/커피, 건축/디자인, 전시/예술, 자연 풍경, 자연/아웃도어, 공부/작업, 문화/건축, 독서, 산책.
- Expand concrete interests only a little: 2-4 closely related keywords at most.
- Do not create sensitive personal traits or infer identity, home, wealth, health, religion, politics, age, gender, ethnicity, or relationships.
- Keep final keywords short, natural, and useful for magazine/content recommendation.
- display_keywords is the only list used as UI chips. It must contain complete noun phrases only.
- Never put raw free text, reasons, negative sentences, first-person phrases, clipped text, or labels ending with particles into display_keywords.
- Comparative Korean feedback means the phrase before "보다는/보다/말고" is downweighted or excluded, and the phrase after it is the positive focus.
- Remove duplicates and merge overly similar keywords.
- If a selected chip conflicts with free text, follow the free text.
- If a deselected broad keyword conflicts with a specific positive free-text preference, keep the specific preference and exclude or downweight the broad one.

Example:
free_text_feedback: "나는 활동적인 것보다는 조용한분위기를 좋아해. 여행도 좋아하긴해."
Correct display_keywords: ["조용한 분위기", "여행"]
Correct excluded_keywords or downweighted_keywords: ["활동적인 취향"]
Wrong display_keywords: ["것보다는 사실 조용한 분위기", "여행도", "여행도 좋아하긴해"]

Example:
free_text_feedback: "나 벌레를 무서워해서 자연은 싫어."
Correct display_keywords: []
Correct excluded_keywords: ["자연/아웃도어", "자연 풍경", "자연휴식"]
Wrong display_keywords: ["나 벌레를 무서워", "벌레", "자연"]

Output:
- display_keywords: final UI chip labels only.
- final_keywords: confirmed interest/profile keywords to show and save.
- excluded_keywords: labels to avoid in future recommendations.
- downweighted_keywords: labels to reduce but not fully remove.
- profile_update_summary: one concise Korean sentence.
- clarifying_question: null unless a short question is truly needed.
''';

const Map<String, dynamic> _schema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['summary', 'keywords', 'recommended_question', 'privacy_notes'],
  'properties': {
    'summary': {'type': 'string'},
    'keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['label', 'type', 'confidence', 'evidence', 'status'],
        'properties': {
          'label': {'type': 'string'},
          'type': {
            'type': 'string',
            'enum': [
              'object',
              'place_type',
              'activity',
              'mood',
              'interest',
              'context',
              'preference',
              'negative_signal',
            ],
          },
          'confidence': {'type': 'number'},
          'evidence': {'type': 'string'},
          'status': {
            'type': 'string',
            'enum': ['draft', 'needs_confirmation', 'confirmed', 'removed'],
          },
        },
      },
    },
    'recommended_question': {'type': 'string'},
    'privacy_notes': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
};

const Map<String, dynamic> _refinerSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'display_keywords',
    'final_keywords',
    'excluded_keywords',
    'downweighted_keywords',
    'profile_update_summary',
    'clarifying_question',
  ],
  'properties': {
    'display_keywords': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'final_keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['label', 'type', 'source', 'confidence', 'reason'],
        'properties': {
          'label': {'type': 'string'},
          'type': {
            'type': 'string',
            'enum': [
              'interest',
              'activity',
              'place_type',
              'mood',
              'content',
              'preference',
              'negative_signal',
            ],
          },
          'source': {'type': 'string'},
          'confidence': {'type': 'number'},
          'reason': {'type': 'string'},
        },
      },
    },
    'excluded_keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['label', 'source', 'reason'],
        'properties': {
          'label': {'type': 'string'},
          'source': {'type': 'string'},
          'reason': {'type': 'string'},
        },
      },
    },
    'downweighted_keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['label', 'reason'],
        'properties': {
          'label': {'type': 'string'},
          'reason': {'type': 'string'},
        },
      },
    },
    'profile_update_summary': {'type': 'string'},
    'clarifying_question': {
      'type': ['string', 'null'],
    },
  },
};
