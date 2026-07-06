import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 마이 페이지 — Archive.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  /// (제목, 발행사, 날짜, 썸네일)
  static const List<(String, String, String, String)> _saved = [
    (
      'The beauty of empty space',
      'Openhouse',
      'May 20, 2024',
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'A table, a chair, and the light',
      'ARK Journal',
      'May 18, 2024',
      'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(showBell: false, showSettings: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const SizedBox(height: 6),
              Text(
                'Archive',
                style: logoStyle(
                  size: 32,
                  weight: FontWeight.w500,
                  letterSpacingEm: 0.0,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 18),

              // 저장한 아티클
              SectionHeader(title: 'Saved articles', onViewAll: () {}),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    for (int i = 0; i < _saved.length; i++) ...[
                      if (i > 0)
                        const Divider(
                            color: AppColors.border, height: 1),
                      _SavedTile(item: _saved[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 이번 주 읽기 기록
              const SectionHeader(title: 'This week'),
              const SizedBox(height: 10),
              const _Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Time read',
                            value: '1h 24m',
                            icon: Icons.schedule,
                          ),
                        ),
                        VerticalDivider(
                            color: AppColors.border, width: 1),
                        Expanded(
                          child: _StatItem(
                            label: 'Marks',
                            value: '12',
                            icon: Icons.edit_outlined,
                          ),
                        ),
                        VerticalDivider(
                            color: AppColors.border, width: 1),
                        Expanded(
                          child: _StatItem(
                            label: 'Streak',
                            value: '3 days',
                            icon: Icons.auto_awesome,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 취향 프로필
              const Text(
                'Taste profile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TasteTag('Warm wood'),
                        _TasteTag('Quiet rooms'),
                        _TasteTag('Editorial mood'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/onboarding/profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Refine taste'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 설정 목록
              _Card(
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      onTap: () => _todo(context),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _SettingTile(
                      icon: Icons.person_outline,
                      label: 'Account',
                      onTap: () => _todo(context),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _SettingTile(
                      icon: Icons.contrast,
                      label: 'Appearance',
                      onTap: () => _todo(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _todo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능이에요')),
    );
  }
}

/// 흰색 라운드 카드 컨테이너.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// 저장한 아티클 한 줄.
class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.item});

  final (String, String, String, String) item;

  @override
  Widget build(BuildContext context) {
    final (title, publisher, date, thumb) = item;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: NetworkPhoto(url: thumb, radius: 8),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  publisher,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.bookmark_border,
              size: 20, color: AppColors.ink),
        ],
      ),
    );
  }
}

/// 이번 주 통계 한 칸 (라벨 / 값 / 아이콘).
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, size: 16, color: AppColors.textSecondary),
      ],
    );
  }
}

/// 취향 태그 (크림 배경).
class _TasteTag extends StatelessWidget {
  const _TasteTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
      ),
    );
  }
}

/// 설정 한 줄.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.ink),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
