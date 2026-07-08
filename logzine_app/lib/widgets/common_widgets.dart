import 'package:flutter/material.dart';

import '../theme.dart';
import 'logzine_logo.dart';

/// 메인 화면 공용 상단 바 — (뒤로가기) + LOGZINE + 액션 아이콘.
class LogzineTopBar extends StatelessWidget {
  const LogzineTopBar({
    super.key,
    this.showBack = false,
    this.showBell = true,
    this.showSettings = false,
    this.showDivider = false,
    this.onBellTap,
    this.onSettingsTap,
  });

  final bool showBack;
  final bool showBell;
  final bool showSettings;
  final bool showDivider;
  final VoidCallback? onBellTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final BoxConstraints? iconConstraints = showDivider
        ? const BoxConstraints.tightFor(width: 36, height: 36)
        : null;
    final EdgeInsetsGeometry? iconPadding =
        showDivider ? EdgeInsets.zero : null;
    final Widget topBarRow = Row(
      children: [
        if (showBack) ...[
          IconButton(
            constraints: iconConstraints,
            padding: iconPadding,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          ),
          const SizedBox(width: 2),
        ],
        const LogzineLogo(height: 28),
        const Spacer(),
        if (showBell)
          IconButton(
            constraints: iconConstraints,
            padding: iconPadding,
            onPressed: onBellTap ?? () => _showNotifications(context),
            icon: const Icon(
              Icons.notifications_none,
              size: 23,
              color: AppColors.ink,
            ),
          ),
        if (showSettings)
          IconButton(
            constraints: iconConstraints,
            padding: iconPadding,
            onPressed: onSettingsTap ?? () {},
            icon: const Icon(
              Icons.settings_outlined,
              size: 23,
              color: AppColors.ink,
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(showBack ? 8 : 24, 6, 12, 0),
          child: showDivider
              ? SizedBox(height: 36, child: topBarRow)
              : topBarRow,
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Divider(height: 1, thickness: 0.8, color: AppColors.border),
          ),
      ],
    );
  }
}

/// 알림 바텀시트 — (아이콘, 제목, 시간) 데모 알림 목록.
/// TODO: 실제 알림 데이터 연동 시 이 목록을 서버 데이터로 대체.
void _showNotifications(BuildContext context) {
  const List<(IconData, String, String)> notifications = [
    (Icons.auto_awesome, '취향 분석이 업데이트됐어요', '방금 전'),
    (Icons.menu_book_outlined, 'ROOM NOTE Issue 29가 도착했어요', '2시간 전'),
    (Icons.favorite_border, 'Openhouse가 새 글을 발행했어요', '어제'),
  ];

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            for (final (icon, title, time) in notifications)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EFE6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 17, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
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
        // 잡지 러닝헤드처럼 — 작은 대문자 아이브로우 라벨
        Text(
          title.toUpperCase(),
          style: eyebrowStyle(color: AppColors.ink),
        ),
        const Spacer(),
        if (onViewAll != null)
          InkWell(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'VIEW ALL',
                style: eyebrowStyle(size: 10),
              ),
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
          const Icon(
            Icons.wb_sunny_outlined,
            size: 15,
            color: Color(0xFFE0A83C),
          ),
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
