import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

/// 온보딩 1단계 — 무드 사진 업로드.
class MoodUploadPage extends StatefulWidget {
  const MoodUploadPage({super.key});

  @override
  State<MoodUploadPage> createState() => _MoodUploadPageState();
}

class _MoodUploadPageState extends State<MoodUploadPage> {
  final List<String> _photos = List.of(kMoodPhotos);

  void _addPhoto() {
    // 데모: 지운 사진을 다시 채워 넣는다 (실제 갤러리 연동 전까지).
    final String? missing =
        kMoodPhotos.where((url) => !_photos.contains(url)).firstOrNull;
    if (missing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데모에서는 사진 4장까지 추가할 수 있어요')),
      );
      return;
    }
    setState(() => _photos.add(missing));
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
                        subtitle: 'Help us understand what you love.',
                      ),
                      const SizedBox(height: 24),

                      // 점선 업로드 영역
                      _AddPhotosArea(onTap: _addPhoto),
                      const SizedBox(height: 20),

                      // 업로드된 사진 썸네일
                      Row(
                        children: [
                          for (final url in _photos) ...[
                            Expanded(
                              child: _PhotoThumb(
                                url: url,
                                onRemove: () =>
                                    setState(() => _photos.remove(url)),
                              ),
                            ),
                            if (url != _photos.last) const SizedBox(width: 10),
                          ],
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Ready to read your mood',
                              style: TextStyle(
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

              // 하단 버튼
              OnboardingPrimaryButton(
                label: 'Analyze photos',
                onPressed: () =>
                    Navigator.pushNamed(context, '/onboarding/tags'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
  const _PhotoThumb({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(url: url),
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
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: AppColors.ink,
                ),
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
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

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
