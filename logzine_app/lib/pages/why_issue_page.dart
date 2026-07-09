import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/magazine.dart';
import '../models/publisher_seeds.dart';
import '../models/reader_args.dart';
import '../models/recommendation_route_args.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/publisher_service.dart';
import '../services/recommendation_service.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';
import '../widgets/onboarding_widgets.dart';

/// 추천 이유 상세 — Why this issue.
class WhyIssuePage extends StatefulWidget {
  const WhyIssuePage({super.key});

  @override
  State<WhyIssuePage> createState() => _WhyIssuePageState();
}

class _WhyIssuePageState extends State<WhyIssuePage> {
  Magazine? _magazineArg;
  bool _argsApplied = false;
  List<String> _taste = const [];
  List<String> _tasteBasis = const [];
  TasteJourneyContext? _journey;

  /// 선반/검색에서 탭한 매거진. 인자 없으면 데모(ROOM NOTE) 폴백.
  Magazine get _magazine => _magazineArg ?? kMagazines[2];

  /// 내 취향과 이 매거진의 일치 태그 — 추천 근거.
  List<String> get _matched =>
      RecommendationService.matchedTags(_taste, _magazine);

  /// 이 매거진의 실제 아티클 목록 (In this issue 목차).
  List<Article> _articles = const [];
  bool _recentViewRecorded = false;

  static const String _fallbackPublisherId = 'studio-log';
  static const String _fallbackPublisherName = 'Studio Log';
  static const String _fallbackPublisherImageUrl =
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e'
      '?auto=format&fit=crop&w=400&q=80';

  String get _publisherId {
    if (_magazine.publisherId.isNotEmpty) return _magazine.publisherId;
    return kPublisherByMagazineTitle[_magazine.title]?.id ??
        _fallbackPublisherId;
  }

  String get _publisherName {
    if (_magazine.publisherName.isNotEmpty) return _magazine.publisherName;
    return kPublisherByMagazineTitle[_magazine.title]?.name ??
        _fallbackPublisherName;
  }

  String get _publisherImageUrl =>
      kPublisherImageUrlById[_publisherId] ?? _fallbackPublisherImageUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhyIssueArgs) {
      _magazineArg = args.magazine;
      _tasteBasis = args.tasteBasis;
    } else if (args is Magazine) {
      _magazineArg = args;
    }
    _loadTaste();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    if (_magazine.id.isEmpty) return;
    try {
      final list = await MagazineService().fetchArticles(_magazine.id);
      if (mounted && list.isNotEmpty) {
        setState(() => _articles = list);
        _recordRecentView(list.first);
      }
    } catch (_) {
      // 오프라인 등 — 기본 목차 유지
    }
  }

  Future<void> _recordRecentView(Article article) async {
    if (_recentViewRecorded || _magazine.id.isEmpty) return;
    _recentViewRecorded = true;
    try {
      await MarkService().touchProgress(
        articleId: article.id,
        magazineId: _magazine.id,
      );
    } catch (_) {
      // 비로그인/오프라인 — 최근 본 기록 실패해도 상세 화면은 계속 표시
    }
  }

  /// i번째 아티클의 시작 페이지 — 앞선 편들의 pageCount 누적.
  int _startPageOf(int index) {
    var page = 1;
    for (var i = 0; i < index; i++) {
      page += _articles[i].pageCount;
    }
    return page;
  }

  void _openArticle(Article article) {
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: ReaderArgs(
        title: article.title,
        publisher: _magazine.title,
        magazineId: _magazine.id,
        articleId: article.id,
        coverUrl: _magazine.coverUrl,
      ),
    );
  }

  Future<void> _loadTaste() async {
    try {
      final tags = await UserService().fetchTasteTags();
      if (!mounted || tags == null) return;
      setState(() {
        _taste = _tasteBasis.isEmpty ? tags : _tasteBasis;
      });
    } catch (_) {
      // 비로그인 — 일치 근거 없이 표시
    }
    final journey = await UserService().fetchTasteJourney();
    if (mounted && journey != null && !journey.isEmpty) {
      setState(() => _journey = journey);
    }
  }

  /// 여정 인용 — 일치 태그 중 사진 근거가 저장된 첫 태그.
  /// 여정 데이터가 없으면(수동 선택·구버전 프로필) null → 카드 숨김.
  ({String tag, String evidence, String? question})? get _journeyCue {
    final journey = _journey;
    if (journey == null) return null;
    for (final tag in _matched) {
      final evidence = journey.evidenceByTag[tag];
      if (evidence != null && evidence.isNotEmpty) {
        return (
          tag: tag,
          evidence: evidence,
          question: journey.questions.isEmpty ? null : journey.questions.first,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 바 (뒤로가기 + 로고)
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Why this issue',
                      style: logoStyle(
                        size: 27,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.01,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 매거진 요약 카드
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 132,
                            height: 178,
                            // 선반/가판대에서 표지가 날아와 이어진다
                            child: Hero(
                              tag: magazineHeroTag(_magazine),
                              child: MagazineCover(magazine: _magazine),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  _magazine.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _magazine.tagline,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: AppColors.body,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: 26,
                                  height: 1.2,
                                  color: AppColors.border,
                                ),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '18 min read',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/reader',
                                      arguments: ReaderArgs(
                                        title: _magazine.title,
                                        publisher: _magazine.issue,
                                        // 이 매거진의 아티클을 리더에 로드
                                        magazineId: _magazine.id.isEmpty
                                            ? null
                                            : _magazine.id,
                                        coverUrl: _magazine.coverUrl,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.forest,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(44),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Start reading'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '추천 기준 안내',
                      style: eyebrowStyle(
                        color: AppColors.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '선택 항목이 아닌, 이 이슈가 추천된 이유를 요약한 정보입니다.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReasonSummaryList(
                      items: [
                        _ReasonSummaryItem(
                          icon: Icons.spa_outlined,
                          title: '추천 키워드',
                          // 실제 일치 태그 + 일치율 — 없으면 새로운 발견으로 안내
                          value: _matched.isEmpty
                              ? '새로운 취향 발견'
                              : _matched.take(2).join(', '),
                          description: _matched.isEmpty
                              ? '조용히 살펴볼 만한 새로운 이슈'
                              : '취향 일치 ${RecommendationService.matchPercent(_taste, _magazine)}%',
                        ),
                        const _ReasonSummaryItem(
                          icon: Icons.menu_book_outlined,
                          title: '읽기 분위기',
                          value: '비주얼 에세이',
                          description: '짧게 읽는 구성',
                        ),
                        const _ReasonSummaryItem(
                          icon: Icons.history_rounded,
                          title: '최근 활동 반영',
                          value: '최근 읽기 흐름 기반',
                          description: '둘러본 콘텐츠의 신호를 반영',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 취향 여정 인용 — "이 질문에 고른 사진 때문에" 추천 근거
                    if (_journeyCue != null) ...[
                      _JourneyCueCard(cue: _journeyCue!),
                      const SizedBox(height: 12),
                    ],

                    _EditorialCueCard(tagline: _magazine.tagline),
                    const SizedBox(height: 24),

                    // 이번 호 목차
                    Text(
                      'IN THIS ISSUE',
                      style: eyebrowStyle(color: AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      // 실제 아티클 목차 — 탭하면 해당 편이 리더에 열린다.
                      // (아직 로드 전이면 기본 목차 표시)
                      child: _articles.isEmpty
                          ? const Column(
                              children: [
                                _ContentsRow(
                                  no: '01',
                                  title: 'The grammar of quiet rooms',
                                  page: 4,
                                ),
                                Divider(color: AppColors.border, height: 1),
                                _ContentsRow(
                                  no: '02',
                                  title: 'Materials that hold light',
                                  page: 12,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < _articles.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      color: AppColors.border,
                                      height: 1,
                                    ),
                                  InkWell(
                                    onTap: () => _openArticle(_articles[i]),
                                    child: _ContentsRow(
                                      no: (i + 1).toString().padLeft(2, '0'),
                                      title: _articles[i].title,
                                      page: _startPageOf(i),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'THIS ISSUE IS ABOUT',
                      style: eyebrowStyle(color: AppColors.ink),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // 이 매거진의 태그 — 내 취향과 일치하면 선택 상태로 강조
                        for (final tag
                            in _magazine.tags.isEmpty
                                ? const ['Interior', 'Wood', 'Light', 'Objects']
                                : _magazine.tags)
                          TasteChip(
                            label: tag,
                            selected: _matched.contains(tag),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    OutlinedButton(
                      onPressed: () async {
                        // 실제 제외 — users/{uid}.excludedMagazines에 저장
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          if (_magazine.id.isNotEmpty) {
                            await UserService().excludeMagazine(_magazine.id);
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('이 매거진을 추천에서 제외했어요')),
                          );
                          navigator.pop();
                        } catch (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('로그인하면 추천에서 제외할 수 있어요'),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Not for me'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _IssueBottomActionBar(
              magazine: _magazine,
              publisherId: _publisherId,
              publisherName: _publisherName,
              imageUrl: _publisherImageUrl,
            ),
          ],
        ),
      ),
    );
  }
}

/// 추천 근거 요약 항목. 개별 항목은 선택/탭 영역이 아닌 읽기 전용 정보로 쓴다.
class _ReasonSummaryItem {
  const _ReasonSummaryItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
}

/// 추천 근거 요약 리스트. 카드/버튼처럼 보이지 않도록 평면 구분선 규칙을 유지한다.
class _ReasonSummaryList extends StatelessWidget {
  const _ReasonSummaryList({required this.items});

  final List<_ReasonSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _ReasonSummaryRow(item: items[i]),
              if (i != items.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReasonSummaryRow extends StatelessWidget {
  const _ReasonSummaryRow({required this.item});

  final _ReasonSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Icon(item.icon, size: 17, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 취향 여정 인용 카드 — 온보딩 질문에 고른 사진이 이 추천으로 이어졌음을 보여준다.
class _JourneyCueCard extends StatelessWidget {
  const _JourneyCueCard({required this.cue});

  final ({String tag, String evidence, String? question}) cue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FROM YOUR JOURNEY',
                  style: eyebrowStyle(size: 10, color: AppColors.wine),
                ),
                const SizedBox(height: 8),
                if (cue.question != null) ...[
                  Text(
                    '“${cue.question}”',
                    style: serifHeading(
                      size: 17,
                      weight: FontWeight.w500,
                      letterSpacing: 0,
                      color: AppColors.ink,
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이 질문에 고른 사진에서 ‘${cue.tag}’ 취향을 읽었어요 — ${cue.evidence}',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    '“${cue.evidence}”',
                    style: serifHeading(
                      size: 17,
                      weight: FontWeight.w500,
                      letterSpacing: 0,
                      color: AppColors.ink,
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사진에서 읽은 ‘${cue.tag}’ 취향이 이 매거진과 만났어요.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 추천 이유 아래의 에디토리얼 큐 카드.
class _EditorialCueCard extends StatelessWidget {
  const _EditorialCueCard({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDITOR\'S CUE',
                  style: eyebrowStyle(size: 10, color: AppColors.forest),
                ),
                const SizedBox(height: 8),
                Text(
                  '“$tagline”',
                  style: serifHeading(
                    size: 18,
                    weight: FontWeight.w500,
                    letterSpacing: 0,
                    color: AppColors.ink,
                  ).copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chosen from this issue’s tone and your recent reading signals.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 68,
            height: 76,
            child: NetworkPhoto(url: kMoodPhotos[3], radius: 12),
          ),
        ],
      ),
    );
  }
}

class _IssueBottomActionBar extends StatefulWidget {
  const _IssueBottomActionBar({
    required this.magazine,
    required this.publisherId,
    required this.publisherName,
    required this.imageUrl,
  });

  final Magazine magazine;
  final String publisherId;
  final String publisherName;
  final String imageUrl;

  @override
  State<_IssueBottomActionBar> createState() => _IssueBottomActionBarState();
}

class _IssueBottomActionBarState extends State<_IssueBottomActionBar> {
  bool _following = false;
  bool _subscribed = false;
  bool _busy = false;
  bool _subscriptionBusy = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _loadSubscription();
  }

  @override
  void didUpdateWidget(covariant _IssueBottomActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publisherId != widget.publisherId) {
      _following = false;
      _busy = false;
      _loadFollowing();
    }
    if (oldWidget.magazine.id != widget.magazine.id) {
      _subscribed = false;
      _subscriptionBusy = false;
      _loadSubscription();
    }
  }

  Future<void> _loadFollowing() async {
    final following = await PublisherService().isFollowing(widget.publisherId);
    if (!mounted) return;
    setState(() => _following = following);
  }

  Future<void> _loadSubscription() async {
    if (widget.magazine.id.isEmpty) return;
    final subscribed = await SubscriptionService().isSubscribed(
      widget.magazine.id,
    );
    if (!mounted) return;
    setState(() => _subscribed = subscribed);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final bool nowFollowing = !_following;
    setState(() {
      _busy = true;
      _following = nowFollowing;
    });
    try {
      if (nowFollowing) {
        await PublisherService().follow(
          publisherId: widget.publisherId,
          publisherName: widget.publisherName,
          imageUrl: widget.imageUrl,
        );
      } else {
        await PublisherService().unfollow(widget.publisherId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _following = !nowFollowing);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('처리 중 문제가 발생했어요')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPublisher() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.publisherName,
                style: logoStyle(size: 22, letterSpacingEm: 0.04),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 매거진을 만드는 발행사예요. 팔로우하면 새 소식을 놓치지 않아요.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: AppColors.body,
                ),
              ),
              const SizedBox(height: 16),
              _PublisherFollowSheetButton(
                following: _following,
                busy: _busy,
                onTap: () async {
                  await _toggle();
                  if (mounted) setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSubscribeFlow() async {
    if (_subscriptionBusy) return;
    if (widget.magazine.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이 매거진은 아직 구독할 수 없어요')));
      return;
    }

    final confirmed = await _showSubscriptionConfirmSheet();
    if (confirmed != true || !mounted) return;

    setState(() => _subscriptionBusy = true);
    try {
      if (_subscribed) {
        await SubscriptionService().unsubscribe(widget.magazine.id);
        if (!mounted) return;
        setState(() => _subscribed = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('매거진 구독을 해지했어요')));
      } else {
        await SubscriptionService().subscribeMagazine(widget.magazine);
        if (!mounted) return;
        setState(() => _subscribed = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('매거진을 구독했어요')));
        await _askNotificationPreference();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구독 처리 중 문제가 발생했어요')));
    } finally {
      if (mounted) setState(() => _subscriptionBusy = false);
    }
  }

  Future<bool?> _showSubscriptionConfirmSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _subscribed
                      ? Icons.library_books_outlined
                      : Icons.library_add_outlined,
                  size: 20,
                  color: _subscribed ? AppColors.forest : AppColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.magazine.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: logoStyle(size: 22, letterSpacingEm: 0.04),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _subscribed
                  ? '${widget.magazine.title} 구독을 해지할까요?'
                  : '${widget.magazine.title}를 구독할까요?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subscribed
                  ? 'Library의 Magazine subs 목록에서 제거돼요.'
                  : '구독한 매거진은 Library의 Magazine subs에서 다시 볼 수 있어요.',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.body,
              ),
            ),
            const SizedBox(height: 18),
            _SubscriptionSheetActions(
              secondaryLabel: _subscribed ? '유지하기' : '취소',
              primaryLabel: _subscribed ? '구독 해지' : '구독하기',
              primaryColor: _subscribed ? AppColors.wine : AppColors.forest,
              onSecondary: () => Navigator.pop(context, false),
              onPrimary: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askNotificationPreference() async {
    final wantsNotification = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 20,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '새 발행물 알림',
                    style: logoStyle(size: 22, letterSpacingEm: 0.04),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '새 발행물이 올라오면 알림을 받을까요?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.magazine.title}의 새 이슈 알림 설정을 저장해둘게요.',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.body,
              ),
            ),
            const SizedBox(height: 18),
            _SubscriptionSheetActions(
              secondaryLabel: '나중에',
              primaryLabel: '알림 받기',
              primaryColor: AppColors.forest,
              onSecondary: () => Navigator.pop(context, false),
              onPrimary: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (wantsNotification == null || !mounted) return;
    await SubscriptionService().setNotifications(
      magazineId: widget.magazine.id,
      enabled: wantsNotification,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      decoration: const BoxDecoration(
        color: AppColors.screen,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _IssueActionItem(
            icon: _subscribed
                ? Icons.library_books_outlined
                : Icons.library_add_outlined,
            label: _subscribed ? 'Subscribed' : 'Subscribe',
            active: _subscribed,
            busy: _subscriptionBusy,
            onTap: _showSubscribeFlow,
          ),
          _IssueActionItem(
            icon: Icons.apartment_outlined,
            label: 'Publisher',
            active: _following,
            busy: _busy,
            onTap: _showPublisher,
          ),
        ],
      ),
    );
  }
}

class _IssueActionItem extends StatelessWidget {
  const _IssueActionItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.forest : AppColors.ink;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionSheetActions extends StatelessWidget {
  const _SubscriptionSheetActions({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onSecondary,
    required this.onPrimary,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondary,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(secondaryLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}

class _PublisherFollowSheetButton extends StatelessWidget {
  const _PublisherFollowSheetButton({
    required this.following,
    required this.busy,
    required this.onTap,
  });

  final bool following;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (following) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: busy ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Following'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Follow publisher'),
      ),
    );
  }
}

/// 이번 호 목차 한 줄 (번호 · 제목 · 페이지).
class _ContentsRow extends StatelessWidget {
  const _ContentsRow({
    required this.no,
    required this.title,
    required this.page,
  });

  final String no;
  final String title;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            no,
            style: logoStyle(
              size: 15,
              weight: FontWeight.w600,
              letterSpacingEm: 0.04,
              color: AppColors.wine,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'p.$page',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
