import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_logo.dart';

/// 이메일로 시작 화면 — 이메일 입력 + 소셜 로그인 + 하단 무드 이미지.
class LoginEmailPage extends StatelessWidget {
  const LoginEmailPage({super.key});

  static const String _footImageUrl =
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
      '?auto=format&fit=crop&w=1200&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const LogzineLogo(),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Start with Email',
                      style: logoStyle(
                        size: 30,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.02,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/onboarding/upload'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 22),
                  const _OrDivider(),
                  const SizedBox(height: 22),
                  // 실제 인증 미구현 — 모든 소셜 버튼은 일단 다음 화면으로 이동.
                  _SocialButton(
                    icon: const _KakaoIcon(),
                    label: 'Continue with Kakao',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/onboarding/upload'),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: const Icon(
                      Icons.apple,
                      size: 24,
                      color: Colors.black,
                    ),
                    label: 'Continue with Apple',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/onboarding/upload'),
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: const _GoogleIcon(),
                    label: 'Continue with Google',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/onboarding/upload'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 하단 무드 이미지 (풀블리드)
            Expanded(
              child: Image.network(
                _footImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.placeholder),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(color: AppColors.placeholder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── or ── 구분선.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}

/// 아이콘 + 라벨의 흰색 아웃라인 소셜 로그인 버튼.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 24, height: 24, child: Center(child: icon)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카카오 노란 원 + 검정 말풍선 아이콘.
class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFFEE500),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble,
        size: 11,
        color: Color(0xFF191919),
      ),
    );
  }
}

/// 구글 'G' 로고.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double stroke = w * 0.22;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      w - stroke,
      w - stroke,
    );
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // 빨강(상단) → 노랑(좌측) → 초록(하단) → 파랑(우측 + 가로 바)
    arc.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.55, false, arc);
    arc.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.72, math.pi * 0.52, false, arc);
    arc.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.28, math.pi * 0.46, false, arc);
    arc.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.06, math.pi * 0.34, false, arc);

    // 파랑 가로 바
    final Paint bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, w * 0.5 - stroke / 2, w * 0.48, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
