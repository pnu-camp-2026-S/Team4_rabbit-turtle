import 'package:flutter/material.dart';

/// LOGZINE 로고 이미지 (세리프 워드마크 + 초록 북마크 리본).
/// [height] = 표시 높이(px). 가로는 원본 비율(약 3.8:1)로 자동.
class LogzineLogo extends StatelessWidget {
  const LogzineLogo({super.key, this.height = 52});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logzine_logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
