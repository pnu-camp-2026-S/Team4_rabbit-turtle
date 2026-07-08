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

/// "최근 하이라이트" 카드에 표시할 문구.
class _RecentMarkInfo {
  const _RecentMarkInfo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static const demo = _RecentMarkInfo(
    title: 'Recommended based on your recent activity',
    subtitle: 'Refined taste · 2 hours ago',
  );
}

/// 홈 — 매거진 탐색 중심 랜딩 화면.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 홈에 필요한 데이터 묶음 — 추천순으로 배치된 선반 + 사용자 취향 태그.
class _HomeData {
  const _HomeData({required this.shelf, required this.taste});

  final List<Magazine> shelf;
  final List<String> taste;
}

class _HomePageState extends State<HomePage> {
  Future<_HomeData> _homeFuture = _loadHome();
  late final Future<_RecentMarkInfo> _recentMarkFuture = _loadRecentMark();

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
      // 선반 정중앙(Today's Pick)이 큐레이터가 소개할 매거진
      final int center = data.shelf.length > 2 ? 2 : 0;
      final String topPick =
          data.shelf.isEmpty ? '' : data.shelf[center].title;
      setState(() {
        _curatorFuture =
            CuratorService.todayLine(taste: data.taste, topPick: topPick);
      });
    }).catchError((_) {});
  }

  /// 매거진 + 사용자 취향을 불러와 추천순(취향∩태그 점수)으로 선반 배치.
  /// 취향이 없으면(비로그인/온보딩 전) 원래 순서 그대로.
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
      // 비로그인 등 — 개인화 없이 진행
    }

    // "Not for me"로 제외한 매거진은 선반에서 뺀다
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
      daySeed: RecommendationService.todaySeed(), // 동점은 매일 순환
    );
    return _HomeData(
      shelf: RecommendationService.arrangeForShelf(ranked),
      taste: taste,
    );
  }

  /// 사용자의 가장 최근 마크를 인용문으로 변환. 마크가 없거나, 좌표가 가리키는
  /// 아티클/문장을 찾을 수 없으면 데모 문구로 대체.
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
    if (time == null) return '방금 전';
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
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
    // 탭한 매거진을 Why 페이지로 전달 — 매거진별 상세/리더 연결
    await Navigator.pushNamed(context, '/discover/why', arguments: magazine);
    // Not for me 제외 등 반영 — 돌아오면 선반 새로고침
    if (mounted) {
      final next = _loadHome();
      setState(() {
        _homeFuture = next;
      });
      _watchCurator(next);
    }
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
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FutureBuilder<_HomeData>(
                future: _homeFuture,
                builder: (context, snapshot) {
                  final magazines = snapshot.data?.shelf ?? const <Magazine>[];
                  // 데이터 도착 전에 PageView를 만들면 초기 페이지(가운데)가
                  // 0으로 밀리므로, 로드 완료 후에 선반을 만든다.
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
                            // 취향 픽커(편집 모드)로 — 저장 후 홈 새로고침
                            await Navigator.pushNamed(
                              context,
                              '/taste',
                              arguments: 'edit',
                            );
                            if (mounted) {
                              final next = _loadHome();
                              setState(() {
                                _homeFuture = next;
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
                    // 온보딩/Refine에서 저장한 실제 취향 — 없으면 기본 문구
                    FutureBuilder<_HomeData>(
                      future: _homeFuture,
                      builder: (context, snapshot) {
                        final taste = snapshot.data?.taste ?? const <String>[];
                        final labels = taste.isEmpty
                            ? const ['Warm wood', 'Quiet rooms', 'Editorial mood']
                            : taste.take(6).toList();
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              TasteChip(label: labels[i], selected: i == 0),
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
