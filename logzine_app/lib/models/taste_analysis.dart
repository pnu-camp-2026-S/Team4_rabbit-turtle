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
    final feedbackKeywords = _keywordsFromFeedback(trimmedFeedback);

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
      ...feedbackKeywords,
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

  static Set<String> _feedbackRemovedLabels(
    String feedback,
    List<TasteKeyword> keywords,
  ) {
    if (feedback.isEmpty) return const <String>{};
    final lower = feedback.toLowerCase();
    final removed = <String>{};
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
      }
    }
    return removed;
  }

  static List<TasteKeyword> _keywordsFromFeedback(String feedback) {
    if (feedback.isEmpty) return const <TasteKeyword>[];

    final normalized = feedback
        .replaceAll(RegExp(r'예\s*:\s*'), '')
        .replaceAll(RegExp(r'[.!?。！？]'), ',')
        .replaceAll(' 그리고 ', ',')
        .replaceAll(' 보다는 ', ',')
        .replaceAll('보다 ', ',')
        .replaceAll('해서 ', ',');

    final labels = <String>[];
    for (final rawPart in normalized.split(',')) {
      var label = rawPart.trim();
      if (label.isEmpty) continue;
      if (RegExp(r'(아니|싫|제외|빼|삭제|별로)').hasMatch(label)) continue;
      label = label
          .replaceAll(RegExp(r'(좋아서|좋아|원해|선호해|찍었어|느낌|위주로)$'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (label.length < 2) continue;
      if (label.length > 18) label = '${label.substring(0, 18).trim()}...';
      if (!labels.contains(label)) labels.add(label);
      if (labels.length >= 3) break;
    }

    if (labels.isEmpty && feedback.length >= 2) {
      labels.add(
        feedback.length > 18
            ? '${feedback.substring(0, 18).trim()}...'
            : feedback,
      );
    }

    return [
      for (final label in labels)
        TasteKeyword(
          label: label,
          type: TasteKeywordType.preference,
          confidence: 1,
          evidence: '사용자 피드백',
          status: TasteKeywordStatus.confirmed,
        ),
    ];
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
