import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../services/gemini_proxy_service.dart';

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

class PhotoTasteAnalyzer {
  const PhotoTasteAnalyzer._();

  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const String _fallbackModel = 'gemini-2.0-flash';
  static const int _maxAttemptsPerModel = 2;
  static const int _maxPhotosPerAnalysis = 6;

  static Future<TasteAnalysisResult> analyze(List<TastePhoto> photos) async {
    if (photos.isEmpty) {
      throw const TasteAnalysisException('분석할 사진을 먼저 추가해주세요.');
    }
    http.Response? lastResponse;
    Object? lastError;

    for (final model in _candidateModels) {
      for (var attempt = 0; attempt < _maxAttemptsPerModel; attempt++) {
        try {
          final response = await _requestAnalysis(model, photos);
          lastResponse = response;

          if (response.statusCode >= 200 && response.statusCode < 300) {
            try {
              return _resultFromResponse(response, photos);
            } on FormatException catch (error) {
              lastError = error;
            } on TasteAnalysisException catch (error) {
              lastError = error;
            }
          } else if (!_shouldRetryResponse(response)) {
            lastError = TasteAnalysisException(_friendlyHttpError(response));
            break;
          }
        } on TasteAnalysisException {
          rethrow;
        } on TimeoutException catch (error) {
          lastError = error;
        } on http.ClientException catch (error) {
          lastError = error;
        } on FormatException catch (error) {
          lastError = error;
        } on TypeError catch (error) {
          lastError = error;
        }

        if (attempt < _maxAttemptsPerModel - 1) {
          await Future<void>.delayed(_retryDelay(attempt));
        }
      }
    }

    if (lastResponse != null) {
      debugPrint('[PhotoTasteAnalyzer] ${_friendlyHttpError(lastResponse)}');
      return _fallbackAnalysisResult(photos);
    }
    debugPrint(
      '[PhotoTasteAnalyzer] fallback after analysis error: $lastError',
    );
    return _fallbackAnalysisResult(photos);
  }

  static List<String> get _candidateModels {
    final models = <String>[_model, _fallbackModel];
    return models.toSet().toList();
  }

  static Duration _retryDelay(int attempt) {
    return Duration(milliseconds: 900 * (1 << attempt) + 250 * attempt);
  }

  static Future<http.Response> _requestAnalysis(
    String model,
    List<TastePhoto> photos,
  ) {
    return GeminiProxyService.generateContent(
      model: model,
      timeout: const Duration(seconds: 30),
      body: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    '$_prompt\n\nReturn only valid JSON that matches this schema:\n${jsonEncode(_schema)}',
              },
              for (final photo in photos.take(_maxPhotosPerAnalysis))
                {
                  'inlineData': {
                    'mimeType': photo.mimeType,
                    'data': base64Encode(photo.bytes),
                  },
                },
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.2,
          'topP': 0.8,
          'maxOutputTokens': 2048,
        },
      },
    );
  }

  static TasteAnalysisResult _resultFromResponse(
    http.Response response,
    List<TastePhoto> photos,
  ) {
    final decodedRaw = jsonDecode(response.body);
    if (decodedRaw is! Map<String, dynamic>) {
      throw const TasteAnalysisException('Gemini 응답 형식이 예상과 달라요.');
    }
    final decoded = decodedRaw;
    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw const TasteAnalysisException('Gemini 응답에서 분석 JSON을 찾지 못했어요.');
    }

    final data = _decodeObject(outputText);
    final keywords = <TasteKeyword>[];
    final rawKeywords = data['keywords'];
    if (rawKeywords is List<dynamic>) {
      for (final item in rawKeywords) {
        if (item is! Map<String, dynamic>) continue;
        final keyword = _keywordFromJson(item);
        if (keyword == null) continue;
        if (keywords.any((value) => value.label == keyword.label)) continue;
        keywords.add(keyword);
      }
    }

    final rawMoreSignals = data['more_signals'];
    if (rawMoreSignals is List<dynamic>) {
      for (final item in rawMoreSignals) {
        if (item is! String) continue;
        final label = _normalizeFinalLabel(item);
        if (label == null) continue;
        if (keywords.any((value) => value.label == label)) continue;
        keywords.add(_keywordFromUiLabel(label, confidence: 0.72));
      }
    }

    if (keywords.isEmpty) {
      throw const TasteAnalysisException('분석 결과에서 사용할 키워드를 찾지 못했어요.');
    }

    return TasteAnalysisResult(
      photos: photos,
      summary: data['summary'] as String? ?? '사진에서 관심사 후보를 찾았어요.',
      keywords: keywords,
      recommendedQuestion:
          data['recommended_question'] as String? ?? '가장 마음에 드는 후보만 남겨주세요.',
      privacyNotes: [
        for (final note in (data['privacy_notes'] as List<dynamic>? ?? []))
          if (note is String) note,
      ],
    );
  }

  static TasteAnalysisResult _fallbackAnalysisResult(List<TastePhoto> photos) {
    return TasteAnalysisResult(
      photos: photos,
      summary: 'AI 이미지 연결이 막혀 기본 관심사 후보를 먼저 준비했어요. 맞는 키워드만 남기고 자유롭게 수정해주세요.',
      keywords: [
        _keywordFromUiLabel('카페', confidence: 0.55, evidence: '기본 후보'),
        _keywordFromUiLabel('조용한 휴식', confidence: 0.55, evidence: '기본 후보'),
        _keywordFromUiLabel('로컬 탐방', confidence: 0.52, evidence: '기본 후보'),
        _keywordFromUiLabel('전시', confidence: 0.5, evidence: '기본 후보'),
        _keywordFromUiLabel('디자인', confidence: 0.5, evidence: '기본 후보'),
        _keywordFromUiLabel('골목 탐방', confidence: 0.5, evidence: '기본 후보'),
      ],
      recommendedQuestion: '지금 보이는 후보 중 맞는 것만 남겨주세요.',
      privacyNotes: const ['AI 분석 실패 시 기본 후보를 표시함'],
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
      final decodedRaw = jsonDecode(response.body);
      if (decodedRaw is! Map<String, dynamic>) return false;
      final decoded = decodedRaw;
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
    final baseProfile = buildProfile(
      analysis: analysis,
      confirmedLabels: confirmedLabels,
      feedback: feedback,
    );
    final trimmedFeedback = feedback.trim();
    if (trimmedFeedback.isEmpty) return baseProfile;

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
        debugPrint('[TasteKeywordRefiner] ${_friendlyHttpError(response)}');
        throw TasteAnalysisException(_friendlyHttpError(response));
      }

      final outputText = _extractOutputText(_decodeHttpObject(response.body));
      if (outputText == null || outputText.trim().isEmpty) {
        throw const TasteAnalysisException('AI 줄글 분석 결과를 찾지 못했어요.');
      }

      final data = _decodeObject(outputText);
      final excludedLabels = _excludedLabelsFromJson(data);
      final refinedKeywords = _cleanProfileKeywords([
        ..._refinedKeywordsFromJson(data),
      ], excludedLabels: excludedLabels);
      if (refinedKeywords.isEmpty) {
        throw const TasteAnalysisException('AI가 최종 키워드를 확정하지 못했어요.');
      }

      final photoTags = analysis.keywords.map((keyword) {
        return excludedLabels.any(
              (label) => _labelsOverlap(label, keyword.label),
            )
            ? keyword.copyWith(status: TasteKeywordStatus.removed)
            : keyword;
      }).toList();
      final sortedKeywords = _sortFinalKeywords(refinedKeywords);

      return TasteProfileDraft(
        photoTags: photoTags,
        confirmedTags: sortedKeywords,
        preferenceProfile: sortedKeywords,
        summary: _profileSummary(sortedKeywords),
        photos: analysis.photos,
        feedback: trimmedFeedback,
      );
    } catch (error) {
      debugPrint('[TasteKeywordRefiner] failed: $error');
      return _localRefinedProfile(
        analysis: analysis,
        baseProfile: baseProfile,
        confirmedLabels: confirmedLabels,
        feedback: trimmedFeedback,
      );
    }
  }

  static TasteProfileDraft _localRefinedProfile({
    required TasteAnalysisResult analysis,
    required TasteProfileDraft baseProfile,
    required Set<String> confirmedLabels,
    required String feedback,
  }) {
    final excludedLabels = _feedbackRemovedLabels(feedback, analysis.keywords);
    final positiveLabels = _feedbackPositiveLabels(feedback)
        .where(
          (label) => !excludedLabels.any(
            (excludedLabel) => _labelsOverlap(label, excludedLabel),
          ),
        )
        .toList();

    final keywords = <TasteKeyword>[
      for (final label in positiveLabels)
        _keywordFromUiLabel(
          label,
          confidence: 0.96,
          evidence: '줄글 피드백 로컬 보정',
          status: TasteKeywordStatus.confirmed,
        ),
      for (final keyword in baseProfile.preferenceProfile)
        if (!excludedLabels.any(
              (label) => _labelsOverlap(label, keyword.label),
            ) &&
            !positiveLabels.any(
              (label) => _labelsOverlap(label, keyword.label),
            ))
          keyword.copyWith(status: TasteKeywordStatus.confirmed),
    ];

    final cleaned = _sortFinalKeywords(
      _cleanProfileKeywords(keywords, excludedLabels: excludedLabels),
    );
    final finalKeywords = cleaned.isEmpty
        ? baseProfile.preferenceProfile
        : cleaned;
    final photoTags = analysis.keywords.map((keyword) {
      return excludedLabels.any((label) => _labelsOverlap(label, keyword.label))
          ? keyword.copyWith(status: TasteKeywordStatus.removed)
          : keyword.copyWith(
              status: confirmedLabels.contains(keyword.label)
                  ? TasteKeywordStatus.confirmed
                  : keyword.status,
            );
    }).toList();

    return TasteProfileDraft(
      photoTags: photoTags,
      confirmedTags: finalKeywords,
      preferenceProfile: finalKeywords,
      summary: _profileSummary(finalKeywords),
      photos: analysis.photos,
      feedback: feedback,
    );
  }

  static Future<http.Response> _requestKeywordRefinement({
    required List<String> aiKeywords,
    required List<String> selectedKeywords,
    required List<String> deselectedKeywords,
    required String feedback,
  }) {
    final input = {
      'photo_keywords': aiKeywords,
      'selected_keywords': selectedKeywords,
      'deselected_keywords': deselectedKeywords,
      'free_text_feedback': feedback,
      'allowed_ui_keywords': _allowedUiKeywords.toList(),
    };

    return GeminiProxyService.generateContent(
      model: _fallbackModel,
      timeout: const Duration(seconds: 15),
      body: {
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
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
          'topP': 0.8,
          'maxOutputTokens': 1200,
        },
      },
    );
  }

  static List<TasteKeyword> _refinedKeywordsFromJson(
    Map<String, dynamic> json,
  ) {
    final mainItems = json['main_keywords'];
    if (mainItems is List<dynamic>) {
      final keywords = <TasteKeyword>[];
      for (final item in mainItems) {
        if (item is! Map<String, dynamic>) continue;
        final label = _normalizeFinalLabel(
          item['ui_keyword'] as String? ?? item['label'] as String? ?? '',
        );
        if (label == null ||
            keywords.any((keyword) => keyword.label == label)) {
          continue;
        }
        keywords.add(
          _keywordFromUiLabel(
            label,
            confidence: ((item['confidence'] as num?) ?? 0.95).toDouble(),
            evidence: item['reason'] as String? ?? '사용자 피드백 정제',
            status: TasteKeywordStatus.confirmed,
          ),
        );
        if (keywords.length >= 6) break;
      }
      if (keywords.isNotEmpty) return keywords;
    }

    final displayKeywords = _displayKeywordsFromJson(json);
    if (displayKeywords.isNotEmpty) {
      return [
        for (final label in displayKeywords)
          _keywordFromUiLabel(
            label,
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
      final label = _normalizeFinalLabel(
        item['ui_keyword'] as String? ?? item['label'] as String? ?? '',
      );
      if (label == null || label.isEmpty) continue;
      if (keywords.any((keyword) => keyword.label == label)) continue;
      keywords.add(
        _keywordFromUiLabel(
          label,
          confidence: ((item['confidence'] as num?) ?? 0.9).toDouble(),
          evidence: item['reason'] as String? ?? '사용자 피드백 정제',
          status: TasteKeywordStatus.confirmed,
        ),
      );
      if (keywords.length >= 6) break;
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
    final labels = <String>{};
    for (final item in items) {
      final raw = switch (item) {
        String value => value,
        Map<String, dynamic> value =>
          value['ui_keyword'] as String? ?? value['label'] as String? ?? '',
        _ => '',
      };
      final label = _normalizeFinalLabel(raw);
      if (label != null) labels.add(label);
    }
    return labels;
  }

  static Set<String> _feedbackRemovedLabels(
    String feedback,
    List<TasteKeyword> keywords,
  ) {
    if (feedback.isEmpty) return const <String>{};
    final lower = feedback.toLowerCase();
    final removed = <String>{};
    final compact = feedback.replaceAll(RegExp(r'\s+'), '');
    final downweightsActive =
        compact.contains('활동적인') &&
        (compact.contains('보다는') || compact.contains('보다'));
    final negativeSubjects = _negativeSubjects(feedback);
    for (final keyword in keywords) {
      final label = keyword.label;
      final labelLower = label.toLowerCase();
      if (downweightsActive &&
          (keyword.type == TasteKeywordType.activity ||
              keyword.category == 'SPORTS' ||
              _uiKeywordCategories[label] == 'SPORTS')) {
        removed.add(label);
        continue;
      }
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

  static List<String> _feedbackPositiveLabels(String feedback) {
    if (feedback.trim().isEmpty) return const <String>[];

    final labels = <String>[];
    void addLabel(String value) {
      final normalized = _normalizeFinalLabel(_normalizeEnglishKeyword(value));
      if (normalized == null) return;
      if (labels.any((label) => _labelsOverlap(label, normalized))) return;
      labels.add(normalized);
    }

    for (final sentence in feedback.split(RegExp(r'[.!?。！？\n]+'))) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      final compact = trimmed.replaceAll(RegExp(r'\s+'), '');
      final hasNegative = RegExp(
        r'(싫|별로|안좋|안\s*좋|관심\s*없|무서|두려|겁나|제외|빼|삭제|말고|not into|don.?t like|do not like|dislike|hate|exclude|remove)',
        caseSensitive: false,
      ).hasMatch(trimmed);
      final hasPositive = RegExp(
        r'(좋아|좋습니다|관심\s*있|선호|원해|하고\s*싶|즐겨|like|love|prefer|into)',
        caseSensitive: false,
      ).hasMatch(trimmed);

      if (compact.contains('보다는') || compact.contains('보다')) {
        final parts = trimmed.split(RegExp(r'보다는|보다\s+'));
        if (parts.length > 1) addLabel(parts.last);
        continue;
      }
      if (hasPositive && !hasNegative) {
        addLabel(trimmed);
        continue;
      }

      final directLabel = _taxonomyLabelFor(trimmed);
      if (directLabel != null && !hasNegative) addLabel(directLabel);
    }

    final englishPatterns = [
      RegExp(
        r'\b(?:i\s+)?(?:also\s+)?(?:like|love|prefer|am into|want)\s+([a-zA-Z][a-zA-Z\s/&-]{1,28})',
        caseSensitive: false,
      ),
    ];
    for (final pattern in englishPatterns) {
      for (final match in pattern.allMatches(feedback)) {
        addLabel(match.group(1) ?? '');
      }
    }

    return labels.take(6).toList();
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
          type: _typeFromCategory(_uiKeywordCategories[label]) ?? keyword.type,
          confidence: keyword.confidence,
          evidence: keyword.evidence,
          category: _uiKeywordCategories[label],
          mappedConcepts: _uiKeywordConcepts[label] ?? const [],
          status: keyword.status,
        ),
      );
      if (cleaned.length >= 6) break;
    }
    return cleaned;
  }

  static List<TasteKeyword> _sortFinalKeywords(List<TasteKeyword> keywords) {
    final indexed = [
      for (var index = 0; index < keywords.length; index++)
        MapEntry(index, keywords[index]),
    ];
    indexed.sort((left, right) {
      final priorityCompare = _finalKeywordPriority(
        right.value,
      ).compareTo(_finalKeywordPriority(left.value));
      if (priorityCompare != 0) return priorityCompare;

      final confidenceCompare = right.value.confidence.compareTo(
        left.value.confidence,
      );
      if (confidenceCompare != 0) return confidenceCompare;

      return left.key.compareTo(right.key);
    });

    final sorted = indexed.map((entry) => entry.value).toList();
    final diversified = <TasteKeyword>[];
    final remaining = <TasteKeyword>[];
    final seenCategories = <String>{};
    for (final keyword in sorted) {
      final category = keyword.category ?? _uiKeywordCategories[keyword.label];
      if (category != null && seenCategories.add(category)) {
        diversified.add(keyword);
      } else {
        remaining.add(keyword);
      }
    }
    return [...diversified, ...remaining].take(6).toList();
  }

  static int _finalKeywordPriority(TasteKeyword keyword) {
    var score = 0;
    if (keyword.status == TasteKeywordStatus.confirmed) score += 40;
    if (keyword.evidence.contains('줄글') || keyword.evidence.contains('피드백')) {
      score += 30;
    }
    if (keyword.type == TasteKeywordType.preference ||
        keyword.type == TasteKeywordType.interest ||
        keyword.type == TasteKeywordType.context) {
      score += 10;
    }
    return score;
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

    return null;
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
    if (_allowedUiKeywords.contains(value.trim())) return value.trim();

    if (compact.contains('조용한') && compact.contains('분위기')) {
      return '조용한 휴식';
    }
    if (compact.contains('조용한') &&
        (compact.contains('휴식') || compact.contains('쉬'))) {
      return '조용한 휴식';
    }
    if (compact.contains('차분한') || compact.contains('잔잔한')) {
      return '조용한 휴식';
    }
    if (compact.contains('해외') && compact.contains('도시')) {
      return '해외 도시';
    }
    if (compact.contains('도시') && compact.contains('여행')) {
      return '도시 여행';
    }
    if (compact.contains('미식') && compact.contains('여행')) {
      return '미식 여행';
    }
    if (compact.contains('스포츠') && compact.contains('여행')) {
      return '스포츠 여행';
    }
    if (compact.contains('여행')) return '도시 여행';
    if (compact.contains('골목') || compact.contains('도시탐험')) {
      return '골목 탐방';
    }
    if (compact.contains('로컬') || compact.contains('동네')) {
      return '로컬 탐방';
    }
    if (compact.contains('아웃도어') ||
        compact.contains('야외') ||
        compact.contains('자연') ||
        compact.contains('풍경')) {
      return '자연';
    }
    if (compact.contains('공부') ||
        compact.contains('업무') ||
        compact.contains('작업')) {
      return '작업 루틴';
    }
    if (compact.contains('문화') && compact.contains('건축')) {
      return '건축';
    }
    if (compact.contains('건축') || compact.contains('디자인')) {
      return compact.contains('건축') ? '건축' : '디자인';
    }
    if (compact.contains('전시') ||
        compact.contains('갤러리') ||
        compact.contains('예술')) {
      return '전시';
    }
    if (compact.contains('카페') && compact.contains('커피')) {
      return '카페';
    }
    if (compact.contains('카페')) return '카페';
    if (compact.contains('커피')) return '커피';
    if (compact.contains('베이킹') || compact.contains('베이커리')) {
      return '베이커리';
    }
    if (compact.contains('디저트')) return '디저트';
    if (compact.contains('브런치')) return '브런치';
    if (compact.contains('한옥')) return '한옥';
    if (compact.contains('서점')) return '서점';
    if (compact.contains('정원')) return '정원';
    if (compact.contains('축구')) return '축구';
    if (compact.contains('야구')) return '야구';
    if (compact.contains('러닝') || compact.contains('달리기')) return '러닝';
    if (compact.contains('요가')) return '요가';
    if (compact.contains('클라이밍')) return '클라이밍';
    if (compact.contains('경기장')) return '경기장 투어';
    if (compact.contains('스포츠') && compact.contains('관람')) {
      return '스포츠 관람';
    }
    if (compact.contains('재즈')) return '재즈';
    if (compact.contains('인디')) return '인디';
    if (compact.contains('라이브') || compact.contains('공연')) return '라이브 공연';
    if (compact.contains('바이닐')) return '바이닐';
    if (compact.contains('책') || compact.contains('독서')) return '독서';
    if (compact.contains('산책')) return '골목 탐방';
    return null;
  }

  static TasteKeyword? _keywordFromJson(Map<String, dynamic> json) {
    final label = _normalizeFinalLabel(
      json['ui_keyword'] as String? ?? json['label'] as String? ?? '',
    );
    if (label == null) return null;
    final category = json['category'] as String? ?? _uiKeywordCategories[label];
    final concepts = json['mapped_concepts'];
    return TasteKeyword(
      label: label,
      type:
          _typeFromCategory(category) ??
          _typeFromApi(json['type'] as String? ?? 'preference'),
      confidence: ((json['confidence'] as num?) ?? 0.8).toDouble(),
      evidence: json['evidence'] as String? ?? '사진 분석 신호',
      category: category,
      mappedConcepts: concepts is List<dynamic>
          ? [
              for (final item in concepts)
                if (item is String) item,
            ]
          : _uiKeywordConcepts[label] ?? const [],
      status: _statusFromApi(json['status'] as String? ?? 'draft'),
    );
  }

  static TasteKeyword _keywordFromUiLabel(
    String label, {
    double confidence = 0.9,
    String evidence = '분석 신호',
    TasteKeywordStatus status = TasteKeywordStatus.draft,
  }) {
    return TasteKeyword(
      label: label,
      type:
          _typeFromCategory(_uiKeywordCategories[label]) ??
          TasteKeywordType.preference,
      confidence: confidence,
      evidence: evidence,
      category: _uiKeywordCategories[label],
      mappedConcepts: _uiKeywordConcepts[label] ?? const [],
      status: status,
    );
  }

  static TasteKeywordType? _typeFromCategory(String? category) {
    return switch (category) {
      'FOOD' => TasteKeywordType.interest,
      'FASHION' => TasteKeywordType.preference,
      'SPACE' => TasteKeywordType.placeType,
      'TRAVEL' => TasteKeywordType.context,
      'ART' => TasteKeywordType.interest,
      'MUSIC' => TasteKeywordType.interest,
      'SPORTS' => TasteKeywordType.activity,
      'LIFESTYLE' => TasteKeywordType.preference,
      _ => null,
    };
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
      'uncertain' => TasteKeywordStatus.needsConfirmation,
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

  static Map<String, dynamic> _decodeHttpObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const TasteAnalysisException('AI 응답 형식이 예상과 달라요.');
  }

  static Map<String, dynamic> _decodeObject(String text) {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List<dynamic> &&
        decoded.isNotEmpty &&
        decoded.first is Map<String, dynamic>) {
      return decoded.first as Map<String, dynamic>;
    }
    throw const TasteAnalysisException('AI 분석 결과 형식이 예상과 달라요.');
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
      final decodedRaw = jsonDecode(response.body);
      if (decodedRaw is! Map<String, dynamic>) {
        return '이미지 분석 요청이 불안정해요. 잠시 뒤 다시 시도해주세요.';
      }
      final decoded = decodedRaw;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        final status = (error['status'] as String? ?? '').toUpperCase();
        final messageText = message is String ? message : '';
        if (status == 'MISSING_PROXY_URL') {
          return 'Gemini 프록시 주소가 앱에 전달되지 않았어요. env.json 또는 --dart-define-from-file 설정을 확인해주세요.';
        }
        if (status == 'FAILED_PRECONDITION' &&
            messageText.toLowerCase().contains('location')) {
          return 'Gemini API가 현재 프록시 실행 지역을 지원하지 않아요. 프록시 위치나 AI 제공자를 바꿔야 합니다.';
        }
        if (status == 'RESOURCE_EXHAUSTED' || response.statusCode == 429) {
          return 'Gemini API 할당량 또는 요청 한도에 걸렸어요. Google AI Studio/Google Cloud에서 quota와 billing 상태를 확인한 뒤 다시 시도해주세요.';
        }
        if (status == 'UNAVAILABLE' ||
            response.statusCode == 503 ||
            messageText.toLowerCase().contains('high demand')) {
          return 'Gemini 서버가 일시적으로 혼잡해요. 자동 재시도를 했지만 실패했습니다. 잠시 뒤 다시 분석해주세요.';
        }
        if (response.statusCode == 400) {
          return 'Gemini 분석 요청 형식이 맞지 않아요. 모델명과 이미지 형식을 확인해주세요.';
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          return 'Gemini API 권한이 없어요. 서버 함수의 Secret과 권한을 확인해주세요.';
        }
        if (messageText.isNotEmpty) {
          return 'Gemini 분석 요청 실패 (${response.statusCode}): $messageText';
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

const Map<String, String> _uiKeywordCategories = {
  '카페': 'FOOD',
  '커피': 'FOOD',
  '디저트': 'FOOD',
  '베이커리': 'FOOD',
  '브런치': 'FOOD',
  '전통차': 'FOOD',
  '와인': 'FOOD',
  '로컬 맛집': 'FOOD',
  '미니멀': 'FASHION',
  '빈티지': 'FASHION',
  '스트릿': 'FASHION',
  '클래식': 'FASHION',
  '디자이너 브랜드': 'FASHION',
  '스포츠웨어': 'FASHION',
  '액세서리': 'FASHION',
  '데일리룩': 'FASHION',
  '인테리어': 'SPACE',
  '가구': 'SPACE',
  '한옥': 'SPACE',
  '호텔': 'SPACE',
  '전시 공간': 'SPACE',
  '서점': 'SPACE',
  '정원': 'SPACE',
  '복합문화공간': 'SPACE',
  '도시 여행': 'TRAVEL',
  '해외 도시': 'TRAVEL',
  '랜드마크': 'TRAVEL',
  '골목 탐방': 'TRAVEL',
  '자연': 'TRAVEL',
  '숙소': 'TRAVEL',
  '미식 여행': 'TRAVEL',
  '스포츠 여행': 'TRAVEL',
  '전시': 'ART',
  '현대미술': 'ART',
  '건축': 'ART',
  '공예': 'ART',
  '디자인': 'ART',
  '일러스트': 'ART',
  '사진': 'ART',
  '아트페어': 'ART',
  '인디': 'MUSIC',
  '재즈': 'MUSIC',
  '라이브 공연': 'MUSIC',
  '페스티벌': 'MUSIC',
  '플레이리스트': 'MUSIC',
  '바이닐': 'MUSIC',
  '사운드트랙': 'MUSIC',
  '축구': 'SPORTS',
  '야구': 'SPORTS',
  '러닝': 'SPORTS',
  '요가': 'SPORTS',
  '클라이밍': 'SPORTS',
  '스포츠 관람': 'SPORTS',
  '경기장 투어': 'SPORTS',
  '독서': 'LIFESTYLE',
  '웰니스': 'LIFESTYLE',
  '작업 루틴': 'LIFESTYLE',
  '홈라이프': 'LIFESTYLE',
  '반려생활': 'LIFESTYLE',
  '취미 수집': 'LIFESTYLE',
  '조용한 휴식': 'LIFESTYLE',
  '로컬 탐방': 'LIFESTYLE',
};

const Map<String, List<String>> _uiKeywordConcepts = {
  '카페': ['food_drink.cafe'],
  '커피': ['food_drink.coffee'],
  '디저트': ['food_drink.dessert'],
  '베이커리': ['food_drink.bakery'],
  '브런치': ['food_drink.brunch'],
  '전통차': ['food_drink.tea'],
  '와인': ['food_drink.wine'],
  '로컬 맛집': ['food_drink.local_restaurant'],
  '미니멀': ['fashion.minimal'],
  '빈티지': ['fashion.vintage'],
  '스트릿': ['fashion.street'],
  '클래식': ['fashion.classic', 'music.classic'],
  '디자이너 브랜드': ['fashion.designer_brand'],
  '스포츠웨어': ['fashion.sportswear'],
  '액세서리': ['fashion.accessory'],
  '데일리룩': ['fashion.daily_look'],
  '인테리어': ['space.interior'],
  '가구': ['space.furniture'],
  '한옥': ['space.hanok', 'culture.history_tradition'],
  '호텔': ['space.hotel'],
  '전시 공간': ['space.gallery_museum'],
  '서점': ['space.bookstore'],
  '정원': ['space.garden'],
  '복합문화공간': ['space.cultural_complex'],
  '도시 여행': ['travel.city_travel'],
  '해외 도시': ['travel.overseas_city'],
  '랜드마크': ['travel.landmark'],
  '골목 탐방': ['travel.local_walk'],
  '자연': ['travel.nature'],
  '숙소': ['travel.stay'],
  '미식 여행': ['travel.food_travel'],
  '스포츠 여행': ['travel.sports_travel'],
  '전시': ['art.exhibition'],
  '현대미술': ['art.contemporary_art'],
  '건축': ['art.architecture'],
  '공예': ['art.craft'],
  '디자인': ['art.design'],
  '일러스트': ['art.illustration'],
  '사진': ['art.photography'],
  '아트페어': ['art.art_fair'],
  '인디': ['music.indie'],
  '재즈': ['music.jazz'],
  '라이브 공연': ['music.live_performance'],
  '페스티벌': ['music.festival'],
  '플레이리스트': ['music.playlist'],
  '바이닐': ['music.vinyl'],
  '사운드트랙': ['music.soundtrack'],
  '축구': ['sports.football'],
  '야구': ['sports.baseball'],
  '러닝': ['sports.running'],
  '요가': ['sports.yoga'],
  '클라이밍': ['sports.climbing'],
  '스포츠 관람': ['sports.spectating'],
  '경기장 투어': ['sports.stadium_tour'],
  '독서': ['lifestyle.reading'],
  '웰니스': ['lifestyle.wellness'],
  '작업 루틴': ['lifestyle.work_routine'],
  '홈라이프': ['lifestyle.home_life'],
  '반려생활': ['lifestyle.pet_life'],
  '취미 수집': ['lifestyle.hobby_collecting'],
  '조용한 휴식': ['lifestyle.quiet_rest'],
  '로컬 탐방': ['lifestyle.local_exploration'],
};

final Set<String> _allowedUiKeywords = _uiKeywordCategories.keys.toSet();

const String _prompt = '''
Use the Photo Taste Analyzer skill to analyze user photos for LOGZINE, an editorial magazine recommendation app.

Rules:
- Output ONLY UI keywords from this allowed vocabulary:
FOOD: 카페, 커피, 디저트, 베이커리, 브런치, 전통차, 와인, 로컬 맛집
FASHION: 미니멀, 빈티지, 스트릿, 클래식, 디자이너 브랜드, 스포츠웨어, 액세서리, 데일리룩
SPACE: 인테리어, 가구, 한옥, 호텔, 전시 공간, 서점, 정원, 복합문화공간
TRAVEL: 도시 여행, 해외 도시, 랜드마크, 골목 탐방, 자연, 숙소, 미식 여행, 스포츠 여행
ART: 전시, 현대미술, 건축, 공예, 디자인, 일러스트, 사진, 아트페어
MUSIC: 인디, 재즈, 라이브 공연, 페스티벌, 플레이리스트, 바이닐, 클래식, 사운드트랙
SPORTS: 축구, 야구, 러닝, 요가, 클라이밍, 스포츠 관람, 경기장 투어, 스포츠 여행
LIFESTYLE: 독서, 웰니스, 작업 루틴, 홈라이프, 반려생활, 취미 수집, 조용한 휴식, 로컬 탐방
- Do not create free labels outside the vocabulary.
- Do not list every visible object. Keep only recommendation-relevant taste signals.
- Ignore accidental background noise, passersby, small clutter, and sensitive personal attributes.
- Do not infer identity, exact location, home/workplace proximity, wealth, health, religion, politics, relationship, age, gender, or ethnicity.
- Prefer experience-level meanings over raw object labels.
- Return 2-5 strong keywords in "keywords".
- Return 4-8 weaker candidates in "more_signals" when possible; each must also be from the allowed vocabulary and must not overlap keywords.
- Use status "draft" for normal candidates and "uncertain" only when context is weak.
- recommended_question is a short Korean prompt asking the user to keep only fitting candidates.

Examples:
- Hanok cafe photo: keywords 한옥, 카페, 커피; more_signals 조용한 휴식, 골목 탐방.
- Football stadium trip photo: keywords 축구, 경기장 투어; more_signals 스포츠 관람, 스포츠 여행, 랜드마크.
- Jazz bar performance photo: keywords 재즈, 라이브 공연; more_signals 바이닐, 와인.
''';

const String _refinerPrompt = '''
Use the Taste Keyword Refiner skill to merge photo keywords, selected chips, deselected chips, and free-text feedback into final recommendation keywords for LOGZINE.

Rules:
- You are the only component that decides final user taste keywords from free_text_feedback. The app will render and save only main_keywords.
- Output ONLY UI keywords from this allowed vocabulary:
FOOD: 카페, 커피, 디저트, 베이커리, 브런치, 전통차, 와인, 로컬 맛집
FASHION: 미니멀, 빈티지, 스트릿, 클래식, 디자이너 브랜드, 스포츠웨어, 액세서리, 데일리룩
SPACE: 인테리어, 가구, 한옥, 호텔, 전시 공간, 서점, 정원, 복합문화공간
TRAVEL: 도시 여행, 해외 도시, 랜드마크, 골목 탐방, 자연, 숙소, 미식 여행, 스포츠 여행
ART: 전시, 현대미술, 건축, 공예, 디자인, 일러스트, 사진, 아트페어
MUSIC: 인디, 재즈, 라이브 공연, 페스티벌, 플레이리스트, 바이닐, 클래식, 사운드트랙
SPORTS: 축구, 야구, 러닝, 요가, 클라이밍, 스포츠 관람, 경기장 투어, 스포츠 여행
LIFESTYLE: 독서, 웰니스, 작업 루틴, 홈라이프, 반려생활, 취미 수집, 조용한 휴식, 로컬 탐방
- Do semantic interpretation, not word matching. Understand whether a sentence means preference, dislike, fear/avoidance, correction, context, or explanation.
- User free-text feedback always has higher priority than AI guesses and chip state.
- If the user explicitly dislikes, negates, fears, or avoids a meaning, do not make that phrase a keyword. Put the closest UI keyword in excluded_keywords or downweighted_keywords.
- If a sentence says "A보다는 B", A is downweighted/excluded and B is the positive focus.
- If the user adds a new interest in Korean or English, snap it to the closest allowed UI keyword.
- Expand concrete interests only a little: 1-4 closely related UI keywords at most.
- Do not create sensitive personal traits or infer identity, home, wealth, health, religion, politics, age, gender, ethnicity, or relationships.
- Remove duplicates and merge overly similar keywords.
- If a selected chip conflicts with free text, follow the free text.
- If a deselected broad keyword conflicts with a specific positive free-text preference, keep the specific preference and exclude or downweight the broad one.
- Do not use more_signals as final chips after free-text refinement. main_keywords only.

Example:
free_text_feedback: "나는 활동적인 것보다는 조용한분위기를 좋아해. 여행도 좋아하긴해."
Correct main_keywords: ["조용한 휴식", "도시 여행"]
Correct excluded_keywords/downweighted_keywords: [] or a matching UI keyword only if present.
Wrong main_keywords: ["것보다는 사실 조용한 분위기", "여행도", "여행도 좋아하긴해"]

Example:
free_text_feedback: "나 벌레를 무서워해서 자연은 싫어."
Correct main_keywords: []
Correct excluded_keywords: ["자연"]
Wrong main_keywords: ["나 벌레를 무서워", "벌레", "자연"]

Example:
free_text_feedback: "I also like playing soccer."
Correct main_keywords: ["축구"]

Example:
free_text_feedback: "문화생활은 좋은데 등산은 별로야."
Correct main_keywords: ["전시", "전시 공간", "복합문화공간"]
Correct excluded_keywords/downweighted_keywords: ["자연"]

Output:
- main_keywords: final UI keyword objects to show and save.
- more_signals: optional weak UI keyword strings; the app will not show these on the final profile.
- user_text: the original free_text_feedback.
- excluded_keywords: UI keyword objects to avoid in future recommendations.
- downweighted_keywords: UI keyword objects to reduce but not fully remove.
- profile_update_summary: one concise Korean sentence.
''';

const Map<String, dynamic> _schema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'summary',
    'keywords',
    'more_signals',
    'recommended_question',
    'privacy_notes',
  ],
  'properties': {
    'summary': {'type': 'string'},
    'keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'ui_keyword',
          'category',
          'mapped_concepts',
          'confidence',
          'evidence',
          'status',
        ],
        'properties': {
          'ui_keyword': {'type': 'string'},
          'category': {
            'type': 'string',
            'enum': [
              'FOOD',
              'FASHION',
              'SPACE',
              'TRAVEL',
              'ART',
              'MUSIC',
              'SPORTS',
              'LIFESTYLE',
            ],
          },
          'mapped_concepts': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'confidence': {'type': 'number'},
          'evidence': {'type': 'string'},
          'status': {
            'type': 'string',
            'enum': ['draft', 'uncertain'],
          },
        },
      },
    },
    'more_signals': {
      'type': 'array',
      'items': {'type': 'string'},
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
    'main_keywords',
    'more_signals',
    'user_text',
    'excluded_keywords',
    'downweighted_keywords',
    'profile_update_summary',
  ],
  'properties': {
    'main_keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'ui_keyword',
          'category',
          'mapped_concepts',
          'source',
          'confidence',
          'reason',
        ],
        'properties': {
          'ui_keyword': {'type': 'string'},
          'category': {
            'type': 'string',
            'enum': [
              'FOOD',
              'FASHION',
              'SPACE',
              'TRAVEL',
              'ART',
              'MUSIC',
              'SPORTS',
              'LIFESTYLE',
            ],
          },
          'mapped_concepts': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'source': {'type': 'string'},
          'confidence': {'type': 'number'},
          'reason': {'type': 'string'},
        },
      },
    },
    'more_signals': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'user_text': {'type': 'string'},
    'excluded_keywords': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'ui_keyword',
          'category',
          'mapped_concepts',
          'source',
          'reason',
        ],
        'properties': {
          'ui_keyword': {'type': 'string'},
          'category': {'type': 'string'},
          'mapped_concepts': {
            'type': 'array',
            'items': {'type': 'string'},
          },
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
        'required': ['ui_keyword', 'reason'],
        'properties': {
          'ui_keyword': {'type': 'string'},
          'reason': {'type': 'string'},
        },
      },
    },
    'profile_update_summary': {'type': 'string'},
  },
};
