import 'package:flutter/material.dart';

class MyPagePage extends StatelessWidget {
  const MyPagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '마이페이지',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // 마지막 페이지 — 버튼을 누르면 처음(회원가입) 화면으로 돌아간다.
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              ),
              child: const Text('처음으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
