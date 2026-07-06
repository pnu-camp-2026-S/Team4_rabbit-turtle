import 'package:flutter/material.dart';

import '../theme.dart';

/// 세리프 'LOGZINE' 워드마크 + 와인색 밑줄.
class LogzineLogo extends StatelessWidget {
  const LogzineLogo({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LOGZINE',
          textAlign: TextAlign.center,
          style: logoStyle(
            size: size,
            weight: FontWeight.w500,
            letterSpacingEm: 0.32,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 2.4,
          color: AppColors.wine,
        ),
      ],
    );
  }
}
