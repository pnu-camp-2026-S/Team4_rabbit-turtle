import 'package:flutter/material.dart';

import '../theme.dart';

/// 메인 화면 공용 상단 바 — (뒤로가기) + LOGZINE + 액션 아이콘.
class LogzineTopBar extends StatelessWidget {
  const LogzineTopBar({
    super.key,
    this.showBack = false,
    this.showBell = true,
    this.showSettings = false,
  });

  final bool showBack;
  final bool showBell;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 24, 6, 12, 0),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            ),
            const SizedBox(width: 2),
          ],
          Text(
            'LOGZINE',
            style: logoStyle(
              size: 20,
              weight: FontWeight.w600,
              letterSpacingEm: 0.24,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          if (showBell)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none,
                  size: 23, color: AppColors.ink),
            ),
          if (showSettings)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined,
                  size: 23, color: AppColors.ink),
            ),
        ],
      ),
    );
  }
}

/// 섹션 제목 + (선택) View all 링크.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          InkWell(
            onTap: onViewAll,
            child: const Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
                Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
      ],
    );
  }
}

/// ☀ Today's keyword 칩 (홈·리더 공용).
class KeywordChip extends StatelessWidget {
  const KeywordChip({super.key, this.keyword = 'Light'});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined,
              size: 15, color: Color(0xFFE0A83C)),
          const SizedBox(width: 8),
          const Text(
            "Today's keyword: ",
            style: TextStyle(fontSize: 13, color: AppColors.body),
          ),
          Text(
            keyword,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
