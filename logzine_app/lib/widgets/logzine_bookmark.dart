import 'package:flutter/material.dart';

import '../theme.dart';

/// LOGZINE 브랜드 북마크 리본 — 흰 몸통 + 포레스트 그린 사이드밴드.
///
/// 스플래시에서 크게 떠오른 뒤 워드마크의 'I' 자리에 끼워지는 심볼.
/// [height]로 크기를 정하고 가로는 height*[ratio].
class LogzineBookmark extends StatelessWidget {
  const LogzineBookmark({super.key, required this.height, this.ratio = 0.46});

  final double height;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * ratio,
      height: height,
      child: CustomPaint(painter: _BookmarkPainter()),
    );
  }
}

/// 북마크 리본 + LOGZINE 워드마크 세로 잠금형(lockup) 로고 — 리본이 텍스트 위.
/// 스플래시 마무리와 웰컴 화면이 같은 이 로고를 써서 전환이 매끄럽게 이어진다.
class LogzineLockup extends StatelessWidget {
  const LogzineLockup({super.key, this.fontSize = 30});

  final double fontSize;

  static double gapOf(double fs) => fs * 0.34;
  static double ribbonHeightOf(double fs) => fs * 1.5;
  static TextStyle wordStyleOf(double fs) => logoStyle(
    size: fs,
    weight: FontWeight.w500,
    letterSpacingEm: 0.14,
    color: AppColors.ink,
  ).copyWith(decoration: TextDecoration.none);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogzineBookmark(height: ribbonHeightOf(fontSize)),
        SizedBox(height: gapOf(fontSize)),
        Text('LOGZINE', style: wordStyleOf(fontSize)),
      ],
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sw = w * 0.05;

    final Paint whiteFill = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // ── 흰 몸통 (둥근 상단 + 하단 ^ 노치) ──
    final double wl = w * 0.05;
    final double wr = w * 0.80;
    final double wtop = h * 0.06;
    final double wbot = h * 0.86;
    final double wnotch = h * 0.74;
    final double wcr = w * 0.15;
    final Path white = Path()
      ..moveTo(wl, wbot)
      ..lineTo(wl, wtop + wcr)
      ..arcToPoint(
        Offset(wl + wcr, wtop),
        radius: Radius.circular(wcr),
        clockwise: true,
      )
      ..lineTo(wr - wcr, wtop)
      ..arcToPoint(
        Offset(wr, wtop + wcr),
        radius: Radius.circular(wcr),
        clockwise: true,
      )
      ..lineTo(wr, wbot)
      ..lineTo((wl + wr) / 2, wnotch)
      ..close();

    // ── 그린 밴드 (몸통보다 위로 살짝 솟고, 아래로 긴 꼬리) ──
    final double gl = w * 0.58;
    final double gr = w * 0.99;
    final double gtop = h * 0.03;
    final double gbot = h * 1.0;
    final double gnotch = h * 0.90;
    final double gcr = w * 0.18;
    final Path green = Path()
      ..moveTo(gl, gbot)
      ..lineTo(gl, gtop + gcr)
      ..arcToPoint(
        Offset(gl + gcr, gtop),
        radius: Radius.circular(gcr),
        clockwise: true,
      )
      ..lineTo(gr - gcr, gtop)
      ..arcToPoint(
        Offset(gr, gtop + gcr),
        radius: Radius.circular(gcr),
        clockwise: true,
      )
      ..lineTo(gr, gbot)
      ..lineTo((gl + gr) / 2, gnotch)
      ..close();

    final Rect gRect = Rect.fromLTRB(gl, gtop, gr, gbot);
    final Paint greenFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.forest, AppColors.forestDark],
      ).createShader(gRect);

    // 흰 몸통
    canvas.drawPath(white, whiteFill);
    canvas.drawPath(white, stroke);
    // 그린 밴드가 흰 몸통에 드리우는 옅은 그림자
    canvas.drawPath(
      green.shift(Offset(-sw * 0.6, 0)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sw * 0.8),
    );
    // 그린 밴드
    canvas.drawPath(green, greenFill);
    canvas.drawPath(green, stroke);
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter oldDelegate) => false;
}
