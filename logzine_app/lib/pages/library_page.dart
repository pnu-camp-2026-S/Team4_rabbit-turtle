import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import 'reader_page.dart';

/// 내 서재 — My Library.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  static const String _avatarUrl =
      'https://images.unsplash.com/photo-1485955900006-10f4d324d411'
      '?auto=format&fit=crop&w=400&q=80';

  static const List<(String, String)> _publishers = [
    ('Studio Log', 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80'),
    ('Room Note', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=400&q=80'),
    ('Oak Paper', 'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?auto=format&fit=crop&w=400&q=80'),
    ('Still Life', 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80'),
  ];

  /// (제목, 표지, 읽은 %, 발행사) — 최근 본 매거진.
  static const List<(String, String, int, String)> _recent = [
    ('CEREAL', 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=600&q=80', 68, 'Cereal Magazine'),
    ('Quiet Materials', 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=600&q=80', 42, 'Studio Log'),
    ('ROOM NOTES', 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?auto=format&fit=crop&w=600&q=80', 15, 'Room Note'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(showSettings: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const SizedBox(height: 6),
              Text(
                'My Library',
                style: logoStyle(
                  size: 32,
                  weight: FontWeight.w500,
                  letterSpacingEm: 0.0,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // 프로필
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: NetworkPhoto(url: _avatarUrl, radius: 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Min',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _MiniChip('Warm wood'),
                            _MiniChip('Quiet rooms'),
                            _MiniChip('Editorial mood'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 통계 카드
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: 'Magazine subs',
                          value: '12',
                          icon: Icons.menu_book_outlined,
                        ),
                      ),
                      VerticalDivider(
                          color: AppColors.border, width: 1),
                      Expanded(
                        child: _StatColumn(
                          label: 'Publisher follows',
                          value: '8',
                          icon: Icons.person_outline,
                        ),
                      ),
                      VerticalDivider(
                          color: AppColors.border, width: 1),
                      Expanded(
                        child: _StatColumn(
                          label: 'Saved articles',
                          value: '28',
                          icon: Icons.bookmark_border,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // 팔로우한 발행사
              SectionHeader(title: 'Followed publishers', onViewAll: () {}),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (name, url) in _publishers)
                    Column(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 66,
                            height: 66,
                            child: NetworkPhoto(url: url, radius: 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.ink),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.forest,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 26),

              // 최근 본 매거진 (나무 선반)
              SectionHeader(title: 'Recently viewed', onViewAll: () {}),
              const SizedBox(height: 12),
              const _RecentShelf(items: _recent),
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
}

/// 작은 취향 칩.
class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
      ),
    );
  }
}

/// 통계 한 칸 (라벨 / 숫자 / 아이콘).
class _StatColumn extends StatelessWidget {
  const _StatColumn({
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
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, size: 17, color: AppColors.textSecondary),
      ],
    );
  }
}

/// 나무 선반 위 최근 본 매거진 3권 (가운데가 크게).
class _RecentShelf extends StatelessWidget {
  const _RecentShelf({required this.items});

  final List<(String, String, int, String)> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 264,
      child: Stack(
        children: [
          // 선반 판
          Positioned(
            left: -4,
            right: -4,
            bottom: 0,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDCC5A2), Color(0xFFB8986C)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

          // 표지 3권
          Positioned.fill(
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _RecentCover(item: items[0], height: 200),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RecentCover(item: items[1], height: 244),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RecentCover(item: items[2], height: 200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 표지 + 하단 '% read' 진행 카드.
class _RecentCover extends StatelessWidget {
  const _RecentCover({required this.item, required this.height});

  final (String, String, int, String) item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (title, url, percent, publisher) = item;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/reader',
        arguments: ReaderArgs(title: title, publisher: publisher),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkPhoto(url: url, radius: 0),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x80000000), Color(0x00000000)],
                    stops: [0.0, 0.45],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: logoStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      letterSpacingEm: 0.06,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 하단 진행 카드
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percent% read',
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.ink),
                      ),
                      const SizedBox(height: 5),
                      ReadProgressBar(percent: percent),
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

/// 초록 읽기 진행 바 (공용).
class ReadProgressBar extends StatelessWidget {
  const ReadProgressBar({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFFE4E0D6)),
            ),
            FractionallySizedBox(
              widthFactor: percent / 100,
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.forest),
            ),
          ],
        ),
      ),
    );
  }
}
