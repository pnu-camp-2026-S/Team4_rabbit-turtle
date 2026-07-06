import 'package:flutter/material.dart';

import '../theme.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고 배지
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Logzine 시작하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '나만의 매거진을 만들 계정을 만들어 보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 입력 필드
                  const _FieldLabel('이메일'),
                  const SizedBox(height: 8),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('비밀번호'),
                  const SizedBox(height: 8),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(hintText: '8자 이상 입력'),
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('비밀번호 확인'),
                  const SizedBox(height: 8),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(hintText: '비밀번호 다시 입력'),
                  ),
                  const SizedBox(height: 28),

                  // 다음으로
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/interest'),
                    child: const Text('다음'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('로그인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 입력 필드 위에 붙는 작은 라벨.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
