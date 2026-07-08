import 'package:flutter/material.dart';

import '../models/article.dart';
import '../models/magazine.dart';
import '../models/reader_args.dart';
import '../services/magazine_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';
import '../widgets/onboarding_widgets.dart';

class WhyIssuePageArgs {
  const WhyIssuePageArgs({required this.magazine, this.tasteBasis});

  final Magazine magazine;
  final List<String>? tasteBasis;
}

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
  List<String>? _tasteBasisArg;

  /// 선반/검색에서 탭한 매거진. 인자 없으면 데모(ROOM NOTE) 폴백.
  Magazine get _magazine => _magazineArg ?? kMagazines[2];

  /// 내 취향과 이 매거진의 일치 태그 — 추천 근거.
  List<String> get _matched =>
      RecommendationService.matchedTags(_tasteBasis, _magazine);

  List<String> get _tasteBasis =>
      (_tasteBasisArg != null && _tasteBasisArg!.isNotEmpty)
      ? _tasteBasisArg!
      : _taste;

  /// 이 매거진의 실제 아티클 목록 (In this issue 목차).
  List<Article> _articles = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WhyIssuePageArgs) {
      _magazineArg = args.magazine;
      _tasteBasisArg = args.tasteBasis;
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
      if (mounted && list.isNotEmpty) setState(() => _articles = list);
    } catch (_) {
      // 오프라인 등 — 기본 목차 유지
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
      if (mounted && tags != null) setState(() => _taste = tags);
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
            // 상단 바 (뒤로가기 + 로고 + 알림)
            const LogzineTopBar(showBack: true),
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
                                Row(
                                  children: [
                                    Expanded(
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
                                          minimumSize: const Size.fromHeight(
                                            44,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child: const Text('Start reading'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(44, 44),
                                        padding: EdgeInsets.zero,
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.bookmark_border,
                                        size: 19,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Recommended Because',
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
                              title: 'Taste match',
                              // 실제 일치 태그 + 일치율 — 없으면 새로운 발견으로 안내
                              subtitle: _matched.isEmpty
                                  ? '당신을 위한\n새로운 발견'
                                  : '${_matched.take(2).join(', ')}\n'
                                        '${RecommendationService.matchPercent(_tasteBasis, _magazine)}% 일치',
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _ReasonCard(
                              icon: Icons.menu_book_outlined,
                              title: 'Reading style',
                              subtitle: '비주얼 에세이,\n짧은 호흡의 글',
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _ReasonCard(
                              icon: Icons.refresh,
                              title: 'Updated from activity',
                              subtitle: '최근 다듬은\n취향 반영',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 인용 카드
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '“',
                            style: logoStyle(
                              size: 40,
                              weight: FontWeight.w600,
                              letterSpacingEm: 0.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _magazine.tagline,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: AppColors.body,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: NetworkPhoto(url: kMoodPhotos[3], radius: 8),
                          ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.ink,
            ),
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
