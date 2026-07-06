import 'package:flutter/material.dart';

import '../theme.dart';

/// 메인 하단 5탭 내비게이션 (Home / Discover / Library / Saved / My).
///
/// [onSelect]가 있으면(메인 셸 내부) 탭 인덱스만 넘기고,
/// 없으면(셸 밖에 push된 화면) 스택을 비우고 메인 셸의 해당 탭으로 이동한다.
class LogzineBottomNav extends StatelessWidget {
  const LogzineBottomNav({
    super.key,
    required this.currentIndex,
    this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int>? onSelect;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (onSelect != null) {
      onSelect!(index);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
      (route) => false,
      arguments: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.search, 'Discover'),
      (Icons.auto_stories_outlined, 'Library'),
      (Icons.favorite_border, 'Saved'),
      (Icons.person_outline, 'My'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _onTap(context, i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          size: 23,
                          color: i == currentIndex
                              ? AppColors.forest
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == currentIndex
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == currentIndex
                                ? AppColors.forest
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
