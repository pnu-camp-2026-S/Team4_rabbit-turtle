import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/mood_analysis.dart';
import '../services/mood_analyzer.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

/// 업로드된 사진 한 장 — 갤러리에서 고른 bytes 또는 데모용 URL.
class _Photo {
  const _Photo.bytes(this.bytes) : url = null;
  const _Photo.url(this.url) : bytes = null;

  final Uint8List? bytes;
  final String? url;
}

/// 온보딩 1단계 — 무드 사진 업로드.
class MoodUploadPage extends StatefulWidget {
  const MoodUploadPage({super.key});

  @override
  State<MoodUploadPage> createState() => _MoodUploadPageState();
}

class _MoodUploadPageState extends State<MoodUploadPage> {
  static const int _maxPhotos = 8;

  /// 시작은 데모 프리셋 4장 — 갤러리에서 추가하거나 지울 수 있다.
  final List<_Photo> _photos = [
    for (final url in kMoodPhotos) _Photo.url(url),
  ];

  final ImagePicker _picker = ImagePicker();
  bool _analyzing = false;

  /// 갤러리에서 사진 선택 (여러 장).
  Future<void> _addPhoto() async {
    final List<XFile> picked = await _picker.pickMultiImage(
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked.isEmpty || !mounted) return;

    final List<_Photo> added = [];
    for (final file in picked) {
      added.add(_Photo.bytes(await file.readAsBytes()));
    }
    setState(() {
      _photos.addAll(added);
      if (_photos.length > _maxPhotos) {
        _photos.removeRange(_maxPhotos, _photos.length);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진은 최대 8장까지 분석해요')),
        );
      }
    });
  }

  /// 사진들을 AI에 보내 무드 태그를 분석한 뒤 결과와 함께 태그 화면으로.
  /// API 키가 없거나 실패하면 결과 없이 이동 → 태그 화면이 데모 태그로 폴백.
  Future<void> _analyze() async {
    if (_analyzing) return;
    setState(() => _analyzing = true);

    // 프리셋(URL) 사진은 다운로드해서 bytes로 변환
    final List<Uint8List> bytesList = [];
    for (final photo in _photos) {
      if (photo.bytes != null) {
        bytesList.add(photo.bytes!);
      } else if (photo.url != null) {
        try {
          final res = await http
              .get(Uri.parse(photo.url!))
              .timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) bytesList.add(res.bodyBytes);
        } catch (_) {/* 이 장은 건너뜀 */}
      }
    }

    // 분석 + 최소 연출 시간(1.4초)을 함께 대기
    final results = await Future.wait<dynamic>([
      GeminiMoodAnalyzer().analyze(bytesList),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);

    if (!mounted) return;
    setState(() => _analyzing = false);
    Navigator.pushNamed(
      context,
      '/onboarding/tags',
      arguments: MoodTagsArgs(
        analysis: results[0] as MoodAnalysis?,
        photoBytes: [
          for (final p in _photos)
            if (p.bytes != null) p.bytes!,
        ],
        photoUrls: [
          for (final p in _photos)
            if (p.url != null) p.url!,
        ],
      ),
    );
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

                      // 업로드된 사진 썸네일 (4장 넘으면 줄바꿈)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double size =
                              (constraints.maxWidth - 30) / 4;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final photo in _photos)
                                SizedBox(
                                  width: size,
                                  child: _PhotoThumb(
                                    photo: photo,
                                    onRemove: () => setState(
                                        () => _photos.remove(photo)),
                                  ),
                                ),
                            ],
                          );
                        },
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
                                  ? 'Add photos to read your mood'
                                  : '${_photos.length} photos ready '
                                      '— we\'ll read your mood',
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
                  disabledBackgroundColor:
                      AppColors.forest.withValues(alpha: 0.4),
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

/// 정사각 썸네일 + 우상단 X 삭제 배지. (갤러리 bytes / 데모 URL 모두 지원)
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onRemove});

  final _Photo photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(photo.bytes!, fit: BoxFit.cover),
            )
          else
            NetworkPhoto(url: photo.url!),
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
