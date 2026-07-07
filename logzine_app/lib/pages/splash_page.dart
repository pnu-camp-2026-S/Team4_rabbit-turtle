import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_logo.dart';
import 'login_welcome_page.dart';

/// 앱 시작 스플래시 — 크림 배경에 로고가 떠오른 뒤,
/// 웰컴 화면으로 부드럽게 페이드되며 로고가 제자리를 찾아간다(Hero).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween(begin: 0.94, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // 로고를 잠시 보여준 뒤 웰컴으로 페이드 전환
    Future.delayed(const Duration(milliseconds: 1700), _goWelcome);
  }

  void _goWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondary) =>
            const LoginWelcomePage(),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Hero(
              tag: 'logzine-splash-logo',
              child: LogzineLogo(height: 64),
            ),
          ),
        ),
      ),
    );
  }
}
