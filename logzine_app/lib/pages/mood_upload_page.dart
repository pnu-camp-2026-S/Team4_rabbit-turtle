import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/taste_analysis.dart';
import '../models/taste_journey_questions.dart';
import '../services/photo_taste_analyzer.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show OnboardingHeader, OnboardingTopBar;
import 'mood_tags_page.dart';

/// 온보딩 1단계 — 취향 탐색 여정.
/// 질문을 하나씩 따라가며 사진 한 장으로 답하고,
/// 질문 맥락은 [TastePhoto.question]으로 Gemini 분석에 함께 전달된다.
class MoodUploadPage extends StatefulWidget {
  const MoodUploadPage({super.key});

  @override
  State<MoodUploadPage> createState() => _MoodUploadPageState();
}

class _MoodUploadPageState extends State<MoodUploadPage> {
  /// 분석에 필요한 최소 사진 수 (질문은 건너뛸 수 있지만 여정의 결과물은 필요).
  static const int _minPhotos = 2;

  final ImagePicker _picker = ImagePicker();
  late final List<String> _questions = pickJourneyQuestions();

  /// 질문 인덱스 → 그 질문에 답한 사진.
  final Map<int, TastePhoto> _answers = <int, TastePhoto>{};
  int _step = 0;
  bool _editMode = false;
  bool _argsApplied = false;
  bool _analyzing = false;
  double _analysisProgress = 0;
  Timer? _progressTimer;

  bool get _isLastStep => _step == _questions.length - 1;

  List<TastePhoto> get _photos => [
    for (final index in _answers.keys.toList()..sort()) _answers[index]!,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _editMode = ModalRoute.of(context)?.settings.arguments == 'edit';
    _argsApplied = true;
  }

  Future<void> _pickForCurrentQuestion() async {
    if (_analyzing) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (!mounted || file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _answers[_step] = TastePhoto(
        name: file.name,
        bytes: bytes,
        mimeType: file.mimeType ?? _mimeTypeFromName(file.name),
        question: _questions[_step],
      );
    });
  }

  void _removeCurrentAnswer() {
    if (_analyzing) return;
    setState(() => _answers.remove(_step));
  }

  void _goPrevious() {
    if (_analyzing || _step == 0) return;
    setState(() => _step--);
  }

  void _skipOrNext() {
    if (_analyzing) return;
    if (!_isLastStep) {
      setState(() => _step++);
      return;
    }
    _analyze();
  }

  /// 분석 시작 — 질문 맥락이 실린 사진들로 Gemini 분석 후 태그 화면 이동.
  Future<void> _analyze() async {
    if (_analyzing) return;
    if (_photos.length < _minPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진이 2장 이상 모이면 취향을 읽을 수 있어요')),
      );
      return;
    }
    _startAnalysisProgress();
    try {
      final analysis = await PhotoTasteAnalyzer.analyze(_photos);
      if (!mounted) return;
      setState(() => _analysisProgress = 1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/onboarding/tags',
        arguments: MoodTagsPageArgs(analysis: analysis, editMode: _editMode),
      );
    } on TasteAnalysisException {
      if (!mounted) return;
      await _showAnalyzeErrorDialog();
    } catch (_) {
      if (!mounted) return;
      await _showAnalyzeErrorDialog();
    } finally {
      _stopAnalysisProgress();
    }
  }

  void _startAnalysisProgress() {
    _progressTimer?.cancel();
    setState(() {
      _analyzing = true;
      _analysisProgress = 0.04;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted) return;
      setState(() {
        final next =
            _analysisProgress +
            (_analysisProgress < 0.35
                ? 0.055
                : _analysisProgress < 0.72
                ? 0.035
                : 0.012);
        _analysisProgress = next.clamp(0.0, 0.92);
      });
    });
  }

  void _stopAnalysisProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (mounted) {
      setState(() {
        _analyzing = false;
        _analysisProgress = 0;
      });
    }
  }

  String get _analysisStage {
    if (_analysisProgress < 0.28) return '사진을 정리하는 중이에요';
    if (_analysisProgress < 0.58) return '분위기와 장면을 읽는 중이에요';
    if (_analysisProgress < 0.84) return '취향 키워드를 고르는 중이에요';
    return '결과를 다듬는 중이에요';
  }

  Future<void> _showAnalyzeErrorDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류가 발생했어요'),
        content: const Text('이미지 분석이 잠시 불안정해요. 다시 실행해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAnswer = _answers[_step];
    final bool primaryEnabled =
        !_analyzing && (!_isLastStep || _photos.length >= _minPhotos);

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              OnboardingTopBar(editMode: _editMode),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const OnboardingHeader(
                        title: 'Trace your taste',
                        subtitle: '질문을 따라, 사진 한 장으로 답해보세요.',
                      ),
                      const SizedBox(height: 20),

                      _JourneyProgress(
                        total: _questions.length,
                        current: _step,
                        answered: _answers.keys.toSet(),
                      ),
                      const SizedBox(height: 18),

                      _QuestionCard(
                        index: _step,
                        total: _questions.length,
                        question: _questions[_step],
                        answer: currentAnswer,
                        onPick: _pickForCurrentQuestion,
                        onRemove: _removeCurrentAnswer,
                      ),
                      const SizedBox(height: 16),

                      if (_photos.isNotEmpty) ...[
                        Text(
                          'Collected moments · ${_photos.length}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.body,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 64,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final entry
                                  in _answers.entries.toList()
                                    ..sort((a, b) => a.key.compareTo(b.key)))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _CollectedThumb(
                                    photo: entry.value,
                                    label: '${entry.key + 1}',
                                    onTap: _analyzing
                                        ? null
                                        : () =>
                                              setState(() => _step = entry.key),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _AnalysisStatusCard(
                        photosCount: _photos.length,
                        analyzing: _analyzing,
                        progress: _analysisProgress,
                        stage: _analysisStage,
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 내비게이션 — 이전 · 건너뛰기 · 다음/분석
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _analyzing ? null : _goPrevious,
                      child: const Text(
                        '이전',
                        style: TextStyle(color: AppColors.body),
                      ),
                    ),
                  const Spacer(),
                  if (currentAnswer == null && !_isLastStep)
                    TextButton(
                      onPressed: _analyzing ? null : _skipOrNext,
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(color: AppColors.body),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: primaryEnabled ? _skipOrNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.forest.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: Colors.white70,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _analyzing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${(_analysisProgress * 100).round()}%'),
                        ],
                      )
                    : Text(_isLastStep ? 'Read my taste' : '다음 질문'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

String _mimeTypeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

/// 여정 진행 점 — 답한 질문은 채워지고, 현재 질문은 길게 강조된다.
class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({
    required this.total,
    required this.current,
    required this.answered,
  });

  final int total;
  final int current;
  final Set<int> answered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.forest
                  : answered.contains(i)
                  ? AppColors.forest.withValues(alpha: 0.45)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
        const Spacer(),
        Text(
          '${current + 1} / $total',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.body,
          ),
        ),
      ],
    );
  }
}

/// 질문 한 장 — 질문 텍스트 + 사진 답변 슬롯.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
    required this.onPick,
    required this.onRemove,
  });

  final int index;
  final int total;
  final String question;
  final TastePhoto? answer;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION ${index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              fontSize: 19,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          if (answer == null)
            _AddPhotoArea(onTap: onPick)
          else
            _AnswerPreview(photo: answer!, onReplace: onPick, onRemove: onRemove),
        ],
      ),
    );
  }
}

/// 점선 테두리의 사진 답변 슬롯.
class _AddPhotoArea extends StatelessWidget {
  const _AddPhotoArea({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFCDBFA9),
          radius: 14,
        ),
        child: Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFE6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 26, color: AppColors.ink),
              SizedBox(height: 10),
              Text(
                '이 질문에 답할 사진 고르기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택된 답변 사진 + 교체/삭제.
class _AnswerPreview extends StatelessWidget {
  const _AnswerPreview({
    required this.photo,
    required this.onReplace,
    required this.onRemove,
  });

  final TastePhoto photo;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            photo.bytes,
            height: 190,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.refresh, size: 15, color: AppColors.body),
              label: const Text(
                '다른 사진으로',
                style: TextStyle(fontSize: 13, color: AppColors.body),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 15, color: AppColors.body),
              label: const Text(
                '지우기',
                style: TextStyle(fontSize: 13, color: AppColors.body),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 하단 수집 스트립의 작은 썸네일 (탭하면 해당 질문으로 이동).
class _CollectedThumb extends StatelessWidget {
  const _CollectedThumb({
    required this.photo,
    required this.label,
    required this.onTap,
  });

  final TastePhoto photo;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              photo.bytes,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisStatusCard extends StatelessWidget {
  const _AnalysisStatusCard({
    required this.photosCount,
    required this.analyzing,
    required this.progress,
    required this.stage,
  });

  final int photosCount;
  final bool analyzing;
  final double progress;
  final String stage;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                analyzing ? Icons.auto_awesome_motion : Icons.auto_awesome,
                size: 16,
                color: AppColors.forest,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analyzing
                      ? stage
                      : photosCount == 0
                      ? '질문에 답한 사진이 취향의 단서가 돼요'
                      : '순간 $photosCount개 수집 — 질문 맥락과 함께 분석돼요',
                  style: const TextStyle(fontSize: 14, color: AppColors.body),
                ),
              ),
              if (analyzing) ...[
                const SizedBox(width: 12),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
              ],
            ],
          ),
          if (analyzing) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.sageSoft,
                color: AppColors.forest,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 둥근 사각형 점선 테두리 페인터.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 6;
    const double gap = 5;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
