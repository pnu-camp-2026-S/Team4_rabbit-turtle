import 'package:flutter/material.dart';

import '../theme.dart';

/// 메인 하단 4탭 내비게이션 (Home / Discover / Library / My).
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
    // 잡지 앱에 맞는 얇은 아이콘 세트 — 가판대(펼친 잡지)/검색/서재(북마크)/마이
    const items = [
      (Icons.import_contacts_outlined, 'STAND'),
      (Icons.search, 'DISCOVER'),
      (Icons.bookmark_border, 'LIBRARY'),
      (Icons.person_outline, 'MY'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    label: items[i].$2,
                    button: true,
                    selected: i == currentIndex,
                    child: InkWell(
                      onTap: () => _onTap(context, i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].$1,
                            size: 21,
                            color: i == currentIndex
                                ? AppColors.forest
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            items[i].$2,
                            style: TextStyle(
                              fontSize: 8.5,
                              letterSpacing: 1.2,
                              fontWeight: i == currentIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == currentIndex
                                  ? AppColors.forest
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
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
