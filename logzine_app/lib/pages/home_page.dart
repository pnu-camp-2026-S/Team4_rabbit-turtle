import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/auth_service.dart';
import '../services/curator_service.dart';
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
  const HomePage({super.key});

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
  String? _selectedTasteLabel;

  /// AI 큐레이터 한 줄 — 홈 데이터가 준비되면 취향+오늘의 픽으로 생성.
  Future<String>? _curatorFuture;

  @override
  void initState() {
    super.initState();
    _watchCurator(_homeFuture);
  }

  void _watchCurator(Future<_HomeData> future) {
    future.then((data) {
      if (!mounted) return;
      final int center = data.shelf.length > 2 ? 2 : 0;
      final String topPick =
          data.shelf.isEmpty ? '' : data.shelf[center].title;
      setState(() {
        _curatorFuture =
            CuratorService.todayLine(taste: data.taste, topPick: topPick);
      });
    }).catchError((_) {});
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

    final ranked = RecommendationService.rank(
      taste,
      magazines,
      daySeed: RecommendationService.todaySeed(),
    );

    return _HomeData(
      shelf: RecommendationService.arrangeForShelf(ranked),
      taste: taste,
      catalog: magazines,
    );
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

  String get _greeting {
    final int hour = DateTime.now().hour;

    final String salutation;
    if (hour >= 5 && hour < 12) {
      salutation = 'Good Morning';
    } else if (hour >= 12 && hour < 18) {
      salutation = 'Good Afternoon';
    } else {
      salutation = 'Good Evening';
    }

    final String? userName = AuthService().currentUserName;
    return userName == null ? salutation : '$salutation, $userName';
  }

  /// 오늘의 지면 날짜줄 — WEDNESDAY · JULY 8
  String get _dateLine {
    const weekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }

  Future<void> _openMagazine(BuildContext context, Magazine magazine) async {
    await Navigator.pushNamed(context, '/discover/why', arguments: magazine);
    if (mounted) {
      final next = _loadHome();
      setState(() {
        _homeFuture = next;
      });
      _watchCurator(next);
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

  List<Magazine> _shelfForSelectedTaste(_HomeData data, String? selectedTaste) {
    final ranked = RecommendationService.rank(
      _queryForSelectedTaste(selectedTaste, data.taste),
      data.catalog,
      daySeed: RecommendationService.todaySeed(),
    );
    return RecommendationService.arrangeForShelf(ranked);
  }

  String _lineForSelectedTaste(
    String? selectedTaste,
    List<Magazine> magazines,
  ) {
    if (magazines.isEmpty) return 'Picked from your taste';
    final int center = magazines.length > 2 ? 2 : 0;
    final String topPick = magazines[center].title;
    if (selectedTaste == null) {
      return 'Picked from your taste, start with $topPick.';
    }
    return 'Picked for $selectedTaste, start with $topPick.';
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
                    const SizedBox(height: 8),
                    // ── 오늘의 지면(Front Page) 헤더 ──
                    Text(
                      _greeting,
                      style: logoStyle(
                        size: 19,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.02,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(_dateLine, style: eyebrowStyle()),
                    const SizedBox(height: 12),
                    // AI 큐레이터의 한 줄 — 보일 듯 말 듯, 조용하게
                    FutureBuilder<String>(
                      future: _curatorFuture,
                      builder: (context, snapshot) {
                        final String line =
                            snapshot.data ?? '오늘의 가판대가 도착했어요';
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            line,
                            key: ValueKey(line),
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Today\'s stand',
                      onViewAll: () => Navigator.pushNamed(context, '/stand'),
                    ),
                    const SizedBox(height: 6),
                    // 선택한 취향 칩에 맞춰 바뀌는 선반 안내 (팀원 #90)
                    FutureBuilder<_HomeData>(
                      future: _homeFuture,
                      builder: (context, snapshot) {
                        final _HomeData? data = snapshot.data;
                        final labels = _chipLabels(
                          data?.taste ?? const <String>[],
                        );
                        final selectedTaste = _resolvedSelectedTaste(labels);
                        final magazines = data == null
                            ? const <Magazine>[]
                            : _shelfForSelectedTaste(data, selectedTaste);
                        final line = _lineForSelectedTaste(
                          selectedTaste,
                          magazines,
                        );
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            line,
                            key: ValueKey(line),
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
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
                  final magazines = _shelfForSelectedTaste(data, selectedTaste);
                  if (magazines.isEmpty) {
                    return const SizedBox(height: 320);
                  }
                  return MagazineShelf(
                    magazines: magazines,
                    showTodaysPick: true,
                    onCenterTap: (magazine) => _openMagazine(context, magazine),
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
                        const Spacer(),
                        InkWell(
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              '/taste',
                              arguments: 'edit',
                            );
                            if (mounted) {
                              final next = _loadHome();
                              setState(() {
                                _homeFuture = next;
                                _selectedTasteLabel = null;
                              });
                              _watchCurator(next);
                            }
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Refine',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forest,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.forest,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<_HomeData>(
                      future: _homeFuture,
                      builder: (context, snapshot) {
                        final taste = snapshot.data?.taste ?? const <String>[];
                        final labels = _chipLabels(taste);
                        final selectedTaste = _resolvedSelectedTaste(labels);
                        return Wrap(
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
                                },
                              ),
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

/// "이번 주 나의 표지" 입구 배너 — 미니 표지 + 카피, 탭하면 전체 보기.
class _MyCoverBanner extends StatelessWidget {
  const _MyCoverBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/mycover'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      style: eyebrowStyle(
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '이번 주 나의 표지가 준비됐어요',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.white70),
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
