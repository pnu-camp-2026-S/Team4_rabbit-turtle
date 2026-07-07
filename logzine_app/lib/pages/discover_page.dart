import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/magazine_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';

/// 돋보기 탭 — 검색 전용 화면.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const List<String> _publishers = [
    'AROUND',
    'KINFOLK',
    'CEREAL',
    'Monocle',
    'Openhouse',
  ];

  static const List<String> _popularTags = [
    '#가구',
    '#조용한',
    '#여행',
    '#브랜드',
    '#공간',
    '#빈티지',
    '#미니멀',
    '#패션',
    '#음향',
    '#요리',
  ];

  final TextEditingController _searchController = TextEditingController();
  late final Future<List<Magazine>> _magazinesFuture = _loadMagazines();

  static Future<List<Magazine>> _loadMagazines() async {
    try {
      final magazines = await MagazineService().fetchMagazines();
      return magazines.isEmpty ? kMagazines : magazines;
    } catch (_) {
      return kMagazines;
    }
  }

  /// index가 범위를 벗어나면(Firestore에 아직 다 시드되지 않은 경우) 데모 데이터로 대체.
  static Magazine _magazineAt(List<Magazine> magazines, int index) =>
      index < magazines.length ? magazines[index] : kMagazines[index];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Magazine>>(
      future: _magazinesFuture,
      builder: (context, snapshot) {
        final List<Magazine> magazines = snapshot.data ?? kMagazines;
        final List<_SearchResult> results = [
          _SearchResult(
            title: 'SEONGSU',
            subtitle: 'SUMMER WALK',
            publisher: 'AROUND',
            description: '성수동의 한낮 공원, 오래된 벽돌과 푸른 잎사귀 사이를 걷는 가벼운 산책을 담아냈어요.',
            tags: const ['#가구', '#조명', '#브랜드', '#빈티지'],
            imageUrl: _magazineAt(magazines, 0).coverUrl,
          ),
          _SearchResult(
            title: 'AROUND',
            subtitle: 'SLOW LIFE & GREENERY',
            publisher: 'AROUND',
            description: '차분히 흘러가는 일상을 바라보며 식물로 둘러싸인 느린 라이프스타일을 소개합니다.',
            tags: const ['#가구', '#식물', '#미니멀', '#요리'],
            imageUrl: _magazineAt(magazines, 3).coverUrl,
          ),
          _SearchResult(
            title: 'nice things.',
            subtitle: 'LOCAL HANDCRAFT',
            publisher: 'nice things.',
            description: '손의 온도가 느껴지는 작은 사물들의 이야기. 오래 두고 볼수록 더 좋아지는 브랜드를 모았어요.',
            tags: const ['#브랜드', '#로컬', '#오브제'],
            imageUrl: _magazineAt(magazines, 4).coverUrl,
          ),
        ];

        return _buildScaffold(context, results);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, List<_SearchResult> results) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const LogzineTopBar(showBell: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: logoStyle(
                        size: 34,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const KeywordChip(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        hintText: '매거진, 키워드, 발행사 검색...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Publishers'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final publisher in _publishers)
                          _OutlineChip(label: publisher),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Popular tags'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _popularTags) _OutlineChip(label: tag),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const _SectionLabel('All magazines'),
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
                    for (final result in results) ...[
                      _SearchResultCard(result: result),
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.publisher,
    required this.description,
    required this.tags,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String publisher;
  final String description;
  final List<String> tags;
  final String imageUrl;
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result});

  final _SearchResult result;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/discover/why'),
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
                      NetworkPhoto(url: result.imageUrl, radius: 4),
                      Container(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
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
                              result.publisher,
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
                            text: result.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' · ${result.subtitle}',
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
                      result.description,
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
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in result.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.screen,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
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
