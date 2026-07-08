import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../models/recommendation_route_args.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';
import '../widgets/onboarding_widgets.dart';

class _RecentMarkInfo {
  const _RecentMarkInfo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static const demo = _RecentMarkInfo(
    title: 'Recommended based on your recent activity',
    subtitle: 'Refined taste · 2 hours ago',
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomeData {
  const _HomeData({
    required this.shelf,
    required this.taste,
    required this.catalog,
  });

  final List<Magazine> shelf;
  final List<String> taste;
  final List<Magazine> catalog;
}

class _HomePageState extends State<HomePage> {
  static const List<String> _defaultTasteLabels = [
    'Warm wood',
    'Quiet rooms',
    'Editorial mood',
  ];

  static const Map<String, List<String>> _defaultTasteQueries = {
    'Warm wood': ['인테리어', '가구', '빈티지', '집밥'],
    'Quiet rooms': ['인테리어', '산책', '전시 공간', '작업실'],
    'Editorial mood': ['디자인', '전시', '현대미술', '바이닐', '재즈', '인디'],
  };

  Future<_HomeData> _homeFuture = _loadHome();
  late final Future<_RecentMarkInfo> _recentMarkFuture = _loadRecentMark();
  final MagazineShelfController _shelfController = MagazineShelfController();
  String? _selectedTasteLabel;

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(() {
        _selectedTasteLabel = null;
        _homeFuture = _loadHome();
      });
    }
  }

  static Future<_HomeData> _loadHome() async {
    List<Magazine> magazines;
    try {
      magazines = await MagazineService().fetchMagazines();
      if (magazines.isEmpty) magazines = kMagazines;
    } catch (_) {
      magazines = kMagazines;
    }

    List<String> taste = const [];
    try {
      taste = await UserService().fetchTasteTags() ?? const [];
    } catch (_) {
      // Ignore and keep fallback chips.
    }

    final excluded = await UserService().fetchExcludedMagazineIds();
    if (excluded.isNotEmpty) {
      magazines = [
        for (final m in magazines)
          if (!excluded.contains(m.id)) m,
      ];
    }

    final shelf = RecommendationService.buildInitialShelf(
      taste,
      magazines,
      daySeed: RecommendationService.todaySeed(),
    );

    return _HomeData(shelf: shelf, taste: taste, catalog: magazines);
  }

  static Future<_RecentMarkInfo> _loadRecentMark() async {
    try {
      final marks = await MarkService().fetchRecentMarks(limit: 1);
      if (marks.isEmpty) return _RecentMarkInfo.demo;
      final mark = marks.first;

      final paragraphs = await MagazineService().fetchArticleParagraphs(
        magazineId: mark.magazineId,
        articleId: mark.articleId,
      );
      if (paragraphs == null ||
          mark.paragraphIdx < 0 ||
          mark.paragraphIdx >= paragraphs.length) {
        return _RecentMarkInfo.demo;
      }
      final segments = paragraphs[mark.paragraphIdx];
      if (mark.segmentIdx < 0 || mark.segmentIdx >= segments.length) {
        return _RecentMarkInfo.demo;
      }

      return _RecentMarkInfo(
        title: '"${segments[mark.segmentIdx]}"',
        subtitle: _relativeTime(mark.createdAt),
      );
    } catch (_) {
      return _RecentMarkInfo.demo;
    }
  }

  static String _relativeTime(DateTime? time) {
    if (time == null) return 'Just now';
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  Future<void> _openMagazine(
    BuildContext context,
    Magazine magazine,
    List<String> tasteBasis,
  ) async {
    await Navigator.pushNamed(
      context,
      '/discover/why',
      arguments: WhyIssueArgs(magazine: magazine, tasteBasis: tasteBasis),
    );
    if (mounted) {
      final next = _loadHome();
      setState(() {
        _homeFuture = next;
      });
    }
  }

  List<String> _chipLabels(List<String> taste) {
    if (taste.isEmpty) return _defaultTasteLabels;
    return taste.take(6).toList();
  }

  String? _resolvedSelectedTaste(List<String> labels) {
    if (labels.isEmpty) return null;
    final String? selected = _selectedTasteLabel;
    if (selected != null && labels.contains(selected)) {
      return selected;
    }
    return labels.first;
  }

  List<String> _queryForSelectedTaste(
    String? selectedTaste,
    List<String> taste,
  ) {
    if (selectedTaste == null) return taste;
    return _defaultTasteQueries[selectedTaste] ?? <String>[selectedTaste];
  }

  void _focusShelfForTaste(_HomeData data, String label) {
    final index = RecommendationService.focusIndexForTaste(data.shelf, label);
    if (index == null) return;
    _shelfController.animateToPage(index);
  }

  String? _fallbackNotice(_HomeData data, String? selectedTaste) {
    final result = RecommendationService.listForTaste(
      _queryForSelectedTaste(selectedTaste, data.taste),
      data.catalog,
      daySeed: RecommendationService.todaySeed(),
    );
    if (result.kind != RecommendationMatchKind.fallback ||
        result.basis.isEmpty) {
      return null;
    }
    final label = result.basis.first;
    return '$label 매거진은 아직 준비 중이에요.\n대신 가까운 취향의 매거진을 보여드릴게요.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const LogzineTopBar(
                showBell: false,
                showSettings: false,
                showDivider: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    PageTitleHeader(
                      title: 'Today\'s stand',
                      actionLabel: 'View all',
                      onActionTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/stand',
                          arguments: StandPageArgs(
                            viewAll: true,
                            selectedTaste: _selectedTasteLabel,
                          ),
                        );
                        if (mounted) {
                          setState(() => _homeFuture = _loadHome());
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FutureBuilder<_HomeData>(
                future: _homeFuture,
                builder: (context, snapshot) {
                  final _HomeData? data = snapshot.data;
                  if (data == null) {
                    return const SizedBox(height: 320);
                  }
                  final labels = _chipLabels(data.taste);
                  final selectedTaste = _resolvedSelectedTaste(labels);
                  final magazines = data.shelf;
                  if (magazines.isEmpty) {
                    return const SizedBox(height: 320);
                  }
                  return MagazineShelf(
                    magazines: magazines,
                    controller: _shelfController,
                    showTodaysPick: true,
                    onCenterTap: (magazine) => _openMagazine(
                      context,
                      magazine,
                      _queryForSelectedTaste(selectedTaste, data.taste),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Center(child: ShelfSwipeHint()),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUR TASTE',
                          style: eyebrowStyle(color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<_HomeData>(
                      future: _homeFuture,
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final taste = data?.taste ?? const <String>[];
                        final labels = _chipLabels(taste);
                        final selectedTaste = _resolvedSelectedTaste(labels);
                        final notice = data == null
                            ? null
                            : _fallbackNotice(data, selectedTaste);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (var i = 0; i < labels.length; i++)
                                  TasteChip(
                                    label: labels[i],
                                    selected: labels[i] == selectedTaste,
                                    onTap: () {
                                      if (labels[i] == selectedTaste) return;
                                      setState(() {
                                        _selectedTasteLabel = labels[i];
                                      });
                                      if (data != null) {
                                        _focusShelfForTaste(data, labels[i]);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            if (notice != null) ...[
                              const SizedBox(height: 14),
                              _HomeFallbackNotice(message: notice),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    // 이번 주 나의 표지 — 취향으로 만든 커버 아트 입구
                    const _MyCoverBanner(),
                    const SizedBox(height: 14),
                    FutureBuilder<_RecentMarkInfo>(
                      future: _recentMarkFuture,
                      builder: (context, snapshot) {
                        return _RecentMarkCard(
                          info: snapshot.data ?? _RecentMarkInfo.demo,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFallbackNotice extends StatelessWidget {
  const _HomeFallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.body,
        ),
      ),
    );
  }
}

/// "이번 주 나의 표지" 입구 배너 — 미니 표지 + 카피, 탭하면 전체 보기.
class _MyCoverBanner extends StatelessWidget {
  const _MyCoverBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/mycover'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forest, width: 1.4),
          ),
          child: Row(
            children: [
              // 미니 타이포 표지
              Hero(
                tag: 'my-weekly-cover',
                child: Container(
                  width: 46,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.screen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'L.',
                        style: logoStyle(
                          size: 13,
                          weight: FontWeight.w700,
                          letterSpacingEm: 0.0,
                          color: AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      Container(width: 14, height: 2, color: AppColors.wine),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY COVER',
                      style: eyebrowStyle(size: 10, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '이번 주 나의 표지가 준비됐어요',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.forest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMarkCard extends StatelessWidget {
  const _RecentMarkCard({required this.info});

  final _RecentMarkInfo info;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/discover/why'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 22,
                color: AppColors.ink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
