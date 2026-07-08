import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../theme.dart';
import 'onboarding_widgets.dart';

/// 표지 Hero 전환용 태그 — 선반/가판대/Why 페이지가 같은 태그를 써야
/// 표지가 화면 사이를 날아가며 이어진다.
String magazineHeroTag(Magazine magazine) =>
    'cover-${magazine.id.isEmpty ? magazine.title : magazine.id}';

class MagazineShelf extends StatefulWidget {
  const MagazineShelf({
    super.key,
    required this.magazines,
    this.initialPage = 2,
    this.showTodaysPick = false,
    this.onCenterTap,
  });

  final List<Magazine> magazines;
  final int initialPage;
  final bool showTodaysPick;
  final ValueChanged<Magazine>? onCenterTap;

  @override
  State<MagazineShelf> createState() => _MagazineShelfState();
}

class _MagazineShelfState extends State<MagazineShelf> {
  late final PageController _controller = PageController(
    viewportFraction: 0.52,
    initialPage: widget.initialPage,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 첫 진입 시 선반이 아래에서 떠오르며 나타난다
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 28),
          child: child,
        ),
      ),
      child: SizedBox(
      height: 320,
      child: Stack(
        children: [
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
          PageView.builder(
            controller: _controller,
            itemCount: widget.magazines.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = widget.initialPage.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    page = _controller.page!;
                  }
                  final double delta =
                      (index - page).clamp(-1.0, 1.0).toDouble();
                  final double t = delta.abs();
                  final double scale = 1 - 0.14 * t;
                  final bool isCenter = t < 0.5;

                  // 가판대 효과 — 양옆 잡지가 가운데를 향해 살짝 꺾여 서 있게
                  final Matrix4 stand = Matrix4.identity()
                    ..setEntry(3, 2, 0.0014) // 원근
                    ..rotateY(delta * 0.42);

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: stand,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            if (isCenter) {
                              widget.onCenterTap
                                  ?.call(widget.magazines[index]);
                            } else {
                              _controller.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 264,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _PhysicalMagazine(
                                  magazine: widget.magazines[index],
                                ),
                                // 오늘의 픽 배지 — 중앙 픽에 있을 때만 표시.
                                // 스와이프로 벗어나면 사라지고, 다시 중앙으로
                                // 돌아오면 실시간으로 다시 나타난다.
                                if (widget.showTodaysPick &&
                                    index == widget.initialPage &&
                                    (page - widget.initialPage).abs() < 0.5)
                                  const _TodaysPickBadge(),
                              ],
                            ),
                          ),
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
      ),
    );
  }
}

/// 실물 잡지 — 종이 표지(MagazineCover)에 책 두께(오른쪽 종이 단면),
/// 책등 음영, 바닥 그림자를 더해 가판대에 서 있는 책처럼 보이게 한다.
class _PhysicalMagazine extends StatelessWidget {
  const _PhysicalMagazine({required this.magazine});

  final Magazine magazine;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 종이 단면 (책 두께) — 표지 뒤로 오른쪽에 살짝 보인다
        Positioned(
          right: 0,
          top: 5,
          bottom: 5,
          width: 10,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(2)),
              border: Border.all(color: AppColors.border, width: 0.7),
              gradient: const LinearGradient(
                // 페이지 결 — 미세한 줄무늬 느낌
                colors: [
                  AppColors.card,
                  AppColors.border,
                  AppColors.card,
                  AppColors.border,
                  AppColors.card,
                ],
              ),
            ),
          ),
        ),
        // 표지 본체
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: magazineHeroTag(magazine),
                  child: MagazineCover(magazine: magazine),
                ),
                // 책등 음영 — 왼쪽 제본부의 어두운 결
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 종이 잡지 표지 — 흰 종이 위에 제호·태그라인을 인쇄하고
/// 아래에 표지 사진이 실린 에디토리얼 매거진 레이아웃.
/// 크기에 비례해 글자가 스케일되므로 선반(264px)·목록(126px) 공용.
class MagazineCover extends StatelessWidget {
  const MagazineCover({super.key, required this.magazine});

  final Magazine magazine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight;
        final double pad = h * 0.06;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 표지 사진 — 전면(풀블리드)
                NetworkPhoto(url: magazine.coverUrl, radius: 0),

                // 상단 밝은 스크림 — 제호 가독성
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // 하단 발행 정보용 옅은 스크림
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 제호 (사진 위 상단)
                Positioned(
                  left: pad,
                  right: pad,
                  top: h * 0.05,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        magazine.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: serifHeading(
                          size: h * 0.088,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: h * 0.014),
                      Text(
                        magazine.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: serifHeading(
                          size: h * 0.038,
                          weight: FontWeight.w500,
                          color: AppColors.ink,
                        ).copyWith(height: 1.25),
                      ),
                    ],
                  ),
                ),

                // 발행 정보 (사진 위 하단)
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: h * 0.035,
                  child: Text(
                    magazine.issue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: h * 0.03,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShelfSwipeHint extends StatelessWidget {
  const ShelfSwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    // 조용한 힌트 — 와이어프레임 느낌이 나지 않게 아주 옅게
    return Opacity(
      opacity: 0.55,
      child: Column(
        children: [
          Text(
            'SWIPE THE SHELF',
            style: eyebrowStyle(size: 9.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          const CustomPaint(
            size: Size(96, 8),
            painter: _DoubleArrowPainter(),
          ),
        ],
      ),
    );
  }
}

class _TodaysPickBadge extends StatelessWidget {
  const _TodaysPickBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      top: -12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              "Today's Pick",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleArrowPainter extends CustomPainter {
  const _DoubleArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;
    const double head = 5.0;

    canvas.drawLine(Offset(head, y), Offset(size.width - head, y), paint);
    canvas.drawLine(const Offset(0, 5), Offset(head + 3, y - 4), paint);
    canvas.drawLine(const Offset(0, 5), Offset(head + 3, y + 4), paint);
    canvas.drawLine(
      Offset(size.width, y),
      Offset(size.width - head - 3, y - 4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, y),
      Offset(size.width - head - 3, y + 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DoubleArrowPainter oldDelegate) => false;
}
