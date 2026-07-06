import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 디스커버 홈 — 오늘의 스탠드.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const int _initialPage = 2; // ROOM NOTE가 가운데

  final PageController _shelfController =
      PageController(viewportFraction: 0.52, initialPage: _initialPage);

  final Set<String> _tasteTags = {'Warm wood'};

  @override
  void dispose() {
    _shelfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Today's stand",
                            style: logoStyle(
                              size: 34,
                              weight: FontWeight.w500,
                              letterSpacingEm: 0.0,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Picked from your taste',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 매거진 선반
                    _MagazineShelf(controller: _shelfController),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Swipe the shelf',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: CustomPaint(
                        size: Size(150, 10),
                        painter: _DoubleArrowPainter(),
                      ),
                    ),
                    const SizedBox(height: 26),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your taste',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final tag in const [
                                'Warm wood',
                                'Quiet rooms',
                                'Editorial mood',
                              ])
                                TasteChip(
                                  label: tag,
                                  selected: _tasteTags.contains(tag),
                                  onTap: () => setState(() {
                                    _tasteTags.contains(tag)
                                        ? _tasteTags.remove(tag)
                                        : _tasteTags.add(tag);
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 최근 활동 기반 추천 카드
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/discover/why',
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 22,
                                      color: AppColors.ink,
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Recommended based on your '
                                            'recent activity',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Refined taste · 2 hours ago',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 나무 선반 위에 매거진들이 서 있는 캐러셀.
class _MagazineShelf extends StatelessWidget {
  const _MagazineShelf({required this.controller});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          // 나무 선반
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Container(
              height: 16,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDCC5A2), Color(0xFFB8986C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

          // 매거진 카드들
          PageView.builder(
            controller: controller,
            itemCount: kMagazines.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double page = _DiscoverPageState._initialPage.toDouble();
                  if (controller.hasClients &&
                      controller.position.haveDimensions) {
                    page = controller.page!;
                  }
                  final double t = (page - index).abs().clamp(0.0, 1.0);
                  final double scale = 1 - 0.16 * t;
                  final bool isCenter = t < 0.5;

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {
                          if (isCenter) {
                            Navigator.pushNamed(context, '/discover/why');
                          } else {
                            controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 264,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 16,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: MagazineCover(magazine: kMagazines[index]),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 매거진 표지 — 사진 + 제목/태그라인/호수 오버레이.
class MagazineCover extends StatelessWidget {
  const MagazineCover({super.key, required this.magazine});

  final Magazine magazine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(url: magazine.coverUrl, radius: 0),
          // 텍스트 가독성용 상단 어두운 그라데이션
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8A000000), Color(0x00000000)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0x66000000), Color(0x00000000)],
                stops: [0.0, 0.3],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  magazine.title,
                  style: logoStyle(
                    size: 17,
                    weight: FontWeight.w600,
                    letterSpacingEm: 0.08,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  magazine.tagline,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  magazine.issue,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xD9FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ←──→ 양방향 화살표.
class _DoubleArrowPainter extends CustomPainter {
  const _DoubleArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;
    const double head = 5;

    canvas.drawLine(Offset(head, y), Offset(size.width - head, y), paint);
    // 왼쪽 화살촉
    canvas.drawLine(Offset(0, y), Offset(head + 3, y - 4), paint);
    canvas.drawLine(Offset(0, y), Offset(head + 3, y + 4), paint);
    // 오른쪽 화살촉
    canvas.drawLine(
        Offset(size.width, y), Offset(size.width - head - 3, y - 4), paint);
    canvas.drawLine(
        Offset(size.width, y), Offset(size.width - head - 3, y + 4), paint);
  }

  @override
  bool shouldRepaint(covariant _DoubleArrowPainter oldDelegate) => false;
}
