import 'package:flutter/material.dart';

import '../models/reader_args.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 내 서재 — 구독, 팔로우, 저장 콘텐츠 중심.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

enum _LibrarySummary { magazines, publishers, saved }

class _LibraryPageState extends State<LibraryPage> {
  static const List<(String, String)> _publishers = [
    (
      'Studio Log',
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'Room Note',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'Oak Paper',
      'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?auto=format&fit=crop&w=400&q=80',
    ),
    (
      'Still Life',
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  /// (제목, 표지, 읽은 %, 발행사) — 최근 본 매거진.
  static const List<(String, String, int, String)> _recent = [
    (
      'CEREAL',
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=600&q=80',
      68,
      'Cereal Magazine',
    ),
    (
      'Quiet Materials',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=600&q=80',
      42,
      'Studio Log',
    ),
    (
      'ROOM NOTES',
      'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?auto=format&fit=crop&w=600&q=80',
      15,
      'Room Note',
    ),
  ];

  /// (매거진, 이슈, 표지, 상태)
  static const List<(String, String, String, String)> _subscriptions = [
    (
      'CEREAL',
      'Vol. 34',
      'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=400&q=80',
      'New issue every month',
    ),
    (
      'ROOM NOTE',
      'Issue 28',
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80',
      'Next issue in 6 days',
    ),
  ];

  /// (제목, 발행사, 날짜, 썸네일)
  static const List<(String, String, String, String)> _savedArticles = [
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

  _LibrarySummary _selectedSummary = _LibrarySummary.magazines;

  void _selectSummary(_LibrarySummary summary) {
    setState(() => _selectedSummary = summary);
  }

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
                    const SizedBox(height: 4),
                    const Text(
                      'Subscriptions, follows, and saved reading in one place.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SummaryCardGroup(
                      selected: _selectedSummary,
                      onSelect: _selectSummary,
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _LibraryDetailPanel(
                        key: ValueKey(_selectedSummary),
                        selected: _selectedSummary,
                        subscriptions: _subscriptions,
                        publishers: _publishers,
                        savedArticles: _savedArticles,
                      ),
                    ),
                    const SizedBox(height: 26),
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

/// 상단 요약 카드 묶음.
class _SummaryCardGroup extends StatelessWidget {
  const _SummaryCardGroup({required this.selected, required this.onSelect});

  final _LibrarySummary selected;
  final ValueChanged<_LibrarySummary> onSelect;

  @override
  Widget build(BuildContext context) {
    return _LibraryCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'Magazine subs',
                value: '12',
                icon: Icons.menu_book_outlined,
                active: selected == _LibrarySummary.magazines,
                onTap: () => onSelect(_LibrarySummary.magazines),
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _SummaryItem(
                label: 'Publisher follows',
                value: '8',
                icon: Icons.person_outline,
                active: selected == _LibrarySummary.publishers,
                onTap: () => onSelect(_LibrarySummary.publishers),
              ),
            ),
            const VerticalDivider(color: AppColors.border, width: 1),
            Expanded(
              child: _SummaryItem(
                label: 'Saved articles',
                value: '28',
                icon: Icons.bookmark_border,
                active: selected == _LibrarySummary.saved,
                onTap: () => onSelect(_LibrarySummary.saved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 탭 가능한 요약 카드 한 칸.
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: active ? AppColors.forest : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.forest : AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              icon,
              size: 17,
              color: active ? AppColors.forest : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 요약 카드 아래에 펼쳐지는 상세 정보.
class _LibraryDetailPanel extends StatelessWidget {
  const _LibraryDetailPanel({
    super.key,
    required this.selected,
    required this.subscriptions,
    required this.publishers,
    required this.savedArticles,
  });

  final _LibrarySummary selected;
  final List<(String, String, String, String)> subscriptions;
  final List<(String, String)> publishers;
  final List<(String, String, String, String)> savedArticles;

  @override
  Widget build(BuildContext context) {
    switch (selected) {
      case _LibrarySummary.magazines:
        return _LibraryCard(
          child: Column(
            children: [
              for (int i = 0; i < subscriptions.length; i++) ...[
                if (i > 0) const Divider(color: AppColors.border, height: 1),
                _SubscriptionTile(item: subscriptions[i]),
              ],
            ],
          ),
        );
      case _LibrarySummary.publishers:
        return _LibraryCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (name, url) in publishers)
                  _PublisherBubble(name: name, url: url),
              ],
            ),
          ),
        );
      case _LibrarySummary.saved:
        return _LibraryCard(
          child: Column(
            children: [
              for (int i = 0; i < savedArticles.length; i++) ...[
                if (i > 0) const Divider(color: AppColors.border, height: 1),
                _SavedArticleTile(item: savedArticles[i]),
              ],
            ],
          ),
        );
    }
  }
}

/// 흰색 라운드 카드 컨테이너.
class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

/// 구독 매거진 한 줄.
class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.item});

  final (String, String, String, String) item;

  @override
  Widget build(BuildContext context) {
    final (title, issue, coverUrl, status) = item;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/reader',
        arguments: ReaderArgs(title: title, publisher: issue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 62,
              child: NetworkPhoto(url: coverUrl, radius: 8),
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
                    issue,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 팔로우한 발행사 버블.
class _PublisherBubble extends StatelessWidget {
  const _PublisherBubble({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 58,
              height: 58,
              child: NetworkPhoto(url: url, radius: 0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.ink),
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
    );
  }
}

/// 저장한 글 한 줄.
class _SavedArticleTile extends StatelessWidget {
  const _SavedArticleTile({required this.item});

  final (String, String, String, String) item;

  @override
  Widget build(BuildContext context) {
    final (title, publisher, date, thumb) = item;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/reader',
        arguments: ReaderArgs(title: title, publisher: publisher),
      ),
      child: Padding(
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
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark_border, size: 20, color: AppColors.ink),
          ],
        ),
      ),
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
          Positioned.fill(
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _RecentCover(item: items[0], height: 200)),
                const SizedBox(width: 10),
                Expanded(child: _RecentCover(item: items[1], height: 244)),
                const SizedBox(width: 10),
                Expanded(child: _RecentCover(item: items[2], height: 200)),
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
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percent% read',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.ink,
                        ),
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
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE4E0D6))),
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
