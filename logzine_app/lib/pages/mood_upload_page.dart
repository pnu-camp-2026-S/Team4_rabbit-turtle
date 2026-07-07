import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/taste_analysis.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show OnboardingHeader, OnboardingTopBar;

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
  bool _analyzing = false;

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
    setState(() => _analyzing = true);
    try {
      final analysis = await PhotoTasteAnalyzer.analyze(_photos);
      if (!mounted) return;
      Navigator.pushNamed(context, '/onboarding/tags', arguments: analysis);
    } on TasteAnalysisException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 분석 중 오류가 발생했어요: $error')));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
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
              const OnboardingTopBar(),
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

                      // 상태 표시
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _photos.isEmpty
                                  ? 'Add photos from your device'
                                  : '${_photos.length} photos ready '
                                        '— Gemini will read your mood',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 버튼 — 분석 중에는 스피너 표시
              FilledButton(
                onPressed: _photos.isEmpty ? null : _analyze,
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
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Reading your mood...'),
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
