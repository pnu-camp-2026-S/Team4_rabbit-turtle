import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_logo.dart';

/// 온보딩 첫 화면 — 사진 없이 로고와 카피만 남긴 미니멀 웰컴.
/// 스플래시의 로고가 Hero로 이어져 제자리를 찾아온다.
class LoginWelcomePage extends StatelessWidget {
  const LoginWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 5),

              // 로고 — 스플래시에서 부드럽게 이어짐
              const Center(
                child: Hero(
                  tag: 'logzine-splash-logo',
                  child: LogzineLogo(height: 58),
                ),
              ),
              const SizedBox(height: 26),

              // 카피 — 조용한 에디토리얼 톤
              Text(
                'Curate your quiet taste',
                textAlign: TextAlign.center,
                style: logoStyle(
                  size: 20,
                  weight: FontWeight.w500,
                  letterSpacingEm: 0.04,
                  color: AppColors.body,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '사진 속 취향을 읽고, 당신의 매거진을 골라드려요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(flex: 6),

              // 하단 버튼
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login/email'),
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
                  arguments: 0, // 게스트도 Stand(홈) 탭에서 시작
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
