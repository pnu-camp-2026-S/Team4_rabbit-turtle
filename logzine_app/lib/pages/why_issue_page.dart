import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/magazine.dart';
import '../models/reader_args.dart';
import '../models/recommendation_route_args.dart';
import '../services/magazine_service.dart';
import '../services/mark_service.dart';
import '../services/recommendation_service.dart';
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

  /// 선반/검색에서 탭한 매거진. 인자 없으면 데모(ROOM NOTE) 폴백.
  Magazine get _magazine => _magazineArg ?? kMagazines[2];

  /// 내 취향과 이 매거진의 일치 태그 — 추천 근거.
  List<String> get _matched =>
      RecommendationService.matchedTags(_taste, _magazine);

  /// 이 매거진의 실제 아티클 목록 (In this issue 목차).
  List<Article> _articles = const [];
  bool _recentViewRecorded = false;

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
        title: _magazine.title,
        publisher: _magazine.issue,
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
                      'Why it fits you',
                      style: eyebrowStyle(
                        color: AppColors.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ReasonCard(
                              icon: Icons.spa_outlined,
                              title: 'Taste cue',
                              // 실제 일치 태그 + 일치율 — 없으면 새로운 발견으로 안내
                              subtitle: _matched.isEmpty
                                  ? 'A quiet\nnew find'
                                  : '${_matched.take(2).join(', ')}\n'
                                        '${RecommendationService.matchPercent(_taste, _magazine)}% 일치',
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _ReasonCard(
                              icon: Icons.menu_book_outlined,
                              title: 'Reading mood',
                              subtitle: 'Visual essays\nshort-form pace',
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _ReasonCard(
                              icon: Icons.refresh,
                              title: 'Recent signal',
                              subtitle: 'Reflects your\nlatest activity',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
          ],
        ),
      ),
    );
  }
}

/// 추천 이유 카드 (아이콘 + 제목 + 설명).
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.sageSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.forest),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.38,
              color: AppColors.body,
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
