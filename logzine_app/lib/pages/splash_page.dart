import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_bookmark.dart';
import 'login_welcome_page.dart';

/// 앱 시작 스플래시 —
/// ① 북마크 리본이 크게 떠오르고 → ② 작아지며 텍스트 위 제자리로 올라가고
/// → ③ 아래로 "LOGZINE"이 나타난다.
/// 완성된 로고(리본+워드마크)는 Hero로 웰컴 화면까지 매끄럽게 이어진다.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // 로고 크기 (웰컴 화면과 동일해야 Hero가 크기 변화 없이 매끄럽게 이어짐)
  static const double _fontSize = 34;
  // 북마크가 처음 떠오를 때의 배율
  static const double _bigScale = 3.4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // 조립이 끝나고 잠시 머문 뒤 웰컴으로 전환 (로고는 Hero로 날아간다)
    Future.delayed(const Duration(milliseconds: 3100), _goWelcome);
  }

  void _goWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 720),
        pageBuilder: (context, animation, secondary) =>
            const LoginWelcomePage(),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// t를 구간 [a,b]에서 0→1로 정규화 (구간 밖은 0/1로 클램프).
  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final double ribbonH = LogzineLockup.ribbonHeightOf(_fontSize);
    final double gap = LogzineLockup.gapOf(_fontSize);
    // 텍스트가 안 보여도 레이아웃은 차지 → 큰 리본을 화면 중앙에 두기 위한 보정
    final double startDy = (gap + _fontSize * 1.1) / 2;

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double t = _controller.value;
            final double markIn = Curves.easeOut.transform(_seg(t, 0.0, 0.24));
            final double settle = Curves.easeOutCubic.transform(
              _seg(t, 0.18, 0.66),
            );
            final double lettersIn = Curves.easeOut.transform(
              _seg(t, 0.62, 0.96),
            );

            final double markScale = lerpDouble(_bigScale, 1.0, settle)!;
            final double markDy = startDy * (1 - settle);

            return Hero(
              tag: 'logzine-splash-logo',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 북마크 리본 — 크게 떴다가 작아지며 위 제자리로
                  Transform.translate(
                    offset: Offset(0, markDy),
                    child: Transform.scale(
                      scale: markScale,
                      child: Opacity(
                        opacity: markIn,
                        child: LogzineBookmark(height: ribbonH),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  // LOGZINE — 아래에서 살짝 올라오며 페이드인
                  Opacity(
                    opacity: lettersIn,
                    child: Transform.translate(
                      offset: Offset(0, (1 - lettersIn) * 8),
                      child: Text(
                        'LOGZINE',
                        style: LogzineLockup.wordStyleOf(_fontSize),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
