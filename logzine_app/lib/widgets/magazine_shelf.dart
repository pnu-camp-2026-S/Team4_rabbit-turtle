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
                            widget.onCenterTap?.call(widget.magazines[index]);
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
                          child: Stack(
                            children: [
                              MagazineCover(magazine: widget.magazines[index]),
                              if (_todaysPickVisible &&
                                  index == widget.initialPage &&
                                  isCenter)
                                const _TodaysPickBadge(),
                            ],
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  magazine.issue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
