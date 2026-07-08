import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/magazine_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 검색 화면 데이터 — 매거진 전체 + 사용자 취향(일치 태그 강조용).
class _SearchData {
  const _SearchData({required this.magazines, required this.taste});

  final List<Magazine> magazines;
  final List<String> taste;
}

/// 돋보기 탭 — 검색 전용 화면.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final Future<_SearchData> _dataFuture = _loadData();

  /// 검색어 (실시간 반영)
  String _query = '';

  /// 탭해서 켠 태그 필터 (없으면 null)
  String? _activeTag;

  static Future<_SearchData> _loadData() async {
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
      // 비로그인 — 강조 없이 진행
    }
    return _SearchData(magazines: magazines, taste: taste);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
    // 포커스가 바뀌면 검색창 힌트(오늘의 키워드) 표시 여부를 갱신
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// 검색어·태그 필터를 적용한 매거진 목록.
  List<Magazine> _filter(List<Magazine> magazines) {
    final String q = _query.toLowerCase();
    return magazines.where((m) {
      if (_activeTag != null && !m.tags.contains(_activeTag)) return false;
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.tagline.toLowerCase().contains(q) ||
          m.issue.toLowerCase().contains(q) ||
          m.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// 카탈로그에서 자주 쓰인 순서대로 태그를 뽑는다 (인기 태그).
  static List<String> _popularTagsOf(List<Magazine> magazines) {
    final counts = <String, int>{};
    for (final m in magazines) {
      for (final t in m.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(10).toList();
  }

  void _toggleTag(String tag) {
    setState(() => _activeTag = _activeTag == tag ? null : tag);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SearchData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            const _SearchData(magazines: kMagazines, taste: []);
        return _buildScaffold(context, data);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, _SearchData data) {
    final List<Magazine> results = _filter(data.magazines);
    final List<String> popularTags = _popularTagsOf(data.magazines);
    final List<String> quickNames = [
      for (final m in data.magazines.take(5)) m.title,
    ];
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(showBell: false, showDivider: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: logoStyle(
                        size: 27,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.01,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 오늘의 키워드 = 카탈로그에서 가장 흔한 태그 (실데이터)
                    KeywordChip(
                      keyword: popularTags.isEmpty ? '사진' : popularTags.first,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        // 포커스 전에는 오늘의 키워드를 연하게 안내, 탭하면 사라짐
                        hintText: _searchFocus.hasFocus
                            ? '매거진, 키워드, 발행사 검색...'
                            : "Today's keyword · "
                                  '${popularTags.isEmpty ? 'Light' : popularTags.first}',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Magazines'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in quickNames)
                          _OutlineChip(
                            label: name,
                            onTap: () => _searchController.text = name,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Popular tags'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in popularTags)
                          _OutlineChip(
                            label: '#$tag',
                            selected: _activeTag == tag,
                            onTap: () => _toggleTag(tag),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _SectionLabel(
                          _query.isEmpty && _activeTag == null
                              ? 'All magazines'
                              : 'Results',
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${results.length})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            '검색 결과가 없어요.\n다른 키워드나 태그로 찾아보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    for (final magazine in results) ...[
                      _SearchResultCard(
                        magazine: magazine,
                        matched: RecommendationService.matchedTags(
                          data.taste,
                          magazine,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // 잡지 러닝헤드 스타일 아이브로우 라벨
    return Text(text.toUpperCase(), style: eyebrowStyle(color: AppColors.ink));
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.forest : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.magazine, required this.matched});

  final Magazine magazine;

  /// 사용자 취향과 일치하는 태그 (forest 색으로 강조)
  final List<String> matched;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/discover/why', arguments: magazine),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 74,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkPhoto(url: magazine.coverUrl, radius: 4),
                      Container(color: Colors.black.withValues(alpha: 0.08)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              magazine.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: logoStyle(
                                size: 12,
                                weight: FontWeight.w700,
                                letterSpacingEm: 0.04,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              magazine.issue,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                        children: [
                          TextSpan(
                            text: magazine.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' · ${magazine.issue}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      magazine.tagline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        // 배경 없이 텍스트만 — 내 취향과 일치하는 태그는 forest 강조
                        for (final tag in magazine.tags)
                          Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: matched.contains(tag)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: matched.contains(tag)
                                  ? AppColors.forest
                                  : AppColors.textSecondary,
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
      ),
    );
  }
}
