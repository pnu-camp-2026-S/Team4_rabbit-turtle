import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_logo.dart';

/// 온보딩 첫 화면 — 히어로 이미지 + 이메일 시작 / 둘러보기.
class LoginWelcomePage extends StatelessWidget {
  const LoginWelcomePage({super.key});

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e'
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
            const SizedBox(height: 20),

            // 히어로 이미지 + 좌하단 카피
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.placeholder),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const ColoredBox(color: AppColors.placeholder),
                  ),
                  // 카피 가독성을 위한 은은한 밝은 그라데이션
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.55),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    bottom: 24,
                    child: Text(
                      'Curate your\nquiet taste',
                      style: logoStyle(
                        size: 36,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ).copyWith(height: 1.18),
                    ),
                  ),
                ],
              ),
            ),

            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/login/email'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.mail_outline, size: 19),
                    label: const Text('Start with Email'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/main',
                      (route) => false,
                      arguments: 1, // 게스트는 디스커버 탭에서 시작
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      backgroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Browse without login'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
