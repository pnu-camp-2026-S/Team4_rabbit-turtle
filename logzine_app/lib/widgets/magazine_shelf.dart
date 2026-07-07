import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../theme.dart';
import 'onboarding_widgets.dart';

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
  late bool _todaysPickVisible = widget.showTodaysPick;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  if (_todaysPickVisible &&
                      (page - widget.initialPage).abs() > 0.55) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _todaysPickVisible = false);
                      }
                    });
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
                              children: [
                                _PhysicalMagazine(
                                  magazine: widget.magazines[index],
                                ),
                                if (_todaysPickVisible &&
                                    index == widget.initialPage &&
                                    isCenter)
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
                MagazineCover(magazine: magazine),
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
        final double pad = h * 0.05;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제호 (종이에 인쇄된 제목/태그라인)
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, h * 0.042, pad, h * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        magazine.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: logoStyle(
                          size: h * 0.068,
                          weight: FontWeight.w600,
                          letterSpacingEm: 0.05,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: h * 0.012),
                      Text(
                        magazine.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: h * 0.034,
                          height: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 표지 사진
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: NetworkPhoto(url: magazine.coverUrl, radius: 0),
                  ),
                ),
                // 발행 정보
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: pad,
                    vertical: h * 0.026,
                  ),
                  child: Text(
                    magazine.issue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: h * 0.03,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
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
    return const Column(
      children: [
        Text(
          'Swipe the shelf',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        CustomPaint(
          size: Size(150, 10),
          painter: _DoubleArrowPainter(),
        ),
      ],
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
