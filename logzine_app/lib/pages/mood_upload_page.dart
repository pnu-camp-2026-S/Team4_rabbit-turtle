import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/taste_analysis.dart';
import '../services/photo_taste_analyzer.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show OnboardingHeader, OnboardingTopBar;
import 'mood_tags_page.dart';

/// 온보딩 1단계 — 무드 사진 업로드.
class MoodUploadPage extends StatefulWidget {
  const MoodUploadPage({super.key});

  @override
  State<MoodUploadPage> createState() => _MoodUploadPageState();
}

class _MoodUploadPageState extends State<MoodUploadPage> {
  static const int _maxPhotos = 8;

  final ImagePicker _picker = ImagePicker();
  final List<TastePhoto> _photos = <TastePhoto>[];
  bool _editMode = false;
  bool _argsApplied = false;
  bool _analyzing = false;
  double _analysisProgress = 0;
  Timer? _progressTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _editMode = ModalRoute.of(context)?.settings.arguments == 'edit';
    _argsApplied = true;
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 8장까지 추가할 수 있어요')));
      return;
    }

    final picked = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (!mounted || picked.isEmpty) return;

    final remaining = _maxPhotos - _photos.length;
    final nextPhotos = <TastePhoto>[];
    for (final file in picked.take(remaining)) {
      final bytes = await file.readAsBytes();
      nextPhotos.add(
        TastePhoto(
          name: file.name,
          bytes: bytes,
          mimeType: file.mimeType ?? _mimeTypeFromName(file.name),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _photos.addAll(nextPhotos));
  }

  /// 분석 시작 — 실제 Gemini 이미지 분석 결과를 만든 뒤 태그 확인 화면으로 이동.
  Future<void> _analyze() async {
    if (_analyzing) return;
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
                        title: 'Upload your mood',
                        subtitle: '사진 파일을 골라 실제 AI 분석을 시작해요.',
                      ),
                      const SizedBox(height: 24),

                      // 점선 업로드 영역
                      _AddPhotosArea(onTap: _addPhoto),
                      const SizedBox(height: 20),

                      // 업로드된 사진 썸네일
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final photo in _photos)
                            SizedBox(
                              width: 72,
                              child: _PhotoThumb(
                                photo: photo,
                                onRemove: () =>
                                    setState(() => _photos.remove(photo)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

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

              // 하단 버튼 — 분석 중에는 스피너 표시
              FilledButton(
                onPressed: _photos.isEmpty || _analyzing ? null : _analyze,
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
                    : const Text('Analyze photos'),
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
                      ? 'Add photos from your device'
                      : '$photosCount photos ready — Gemini will read your mood',
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

/// 점선 테두리의 'Add photos' 업로드 영역.
class _AddPhotosArea extends StatelessWidget {
  const _AddPhotosArea({required this.onTap});

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
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFE6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 30, color: AppColors.ink),
              SizedBox(height: 10),
              Text(
                'Add photos',
                style: TextStyle(
                  fontSize: 14.5,
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

/// 정사각 썸네일 + 우상단 X 삭제 배지.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onRemove});

  final TastePhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              photo.bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x22000000), blurRadius: 4),
                  ],
                ),
                child: const Icon(Icons.close, size: 12, color: AppColors.ink),
              ),
            ),
          ),
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
