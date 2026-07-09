import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../models/recommendation_route_args.dart';
import '../services/magazine_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/stand_cue_card.dart';

class _StandData {
  const _StandData({
    required this.catalog,
    required this.shelf,
    required this.taste,
  });

  final List<Magazine> catalog;
  final List<Magazine> shelf;
  final List<String> taste;
}

class StandPage extends StatefulWidget {
  const StandPage({super.key});

  @override
  State<StandPage> createState() => _StandPageState();
}

class _StandPageState extends State<StandPage> {
  static const Map<String, List<String>> _defaultTasteQueries = {
    'Warm wood': ['인테리어', '가구', '빈티지', '집밥'],
    'Quiet rooms': ['인테리어', '산책', '전시 공간', '작업실'],
    'Editorial mood': ['디자인', '전시', '현대미술', '바이닐', '재즈', '인디'],
  };

  Future<_StandData> _standFuture = _loadStand();
  final MagazineShelfController _shelfController = MagazineShelfController();
  bool _argsApplied = false;
  bool _viewAllOnly = false;
  String? _selectedTaste;

  static Future<_StandData> _loadStand() async {
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
    } catch (_) {}

    final excluded = await UserService().fetchExcludedMagazineIds();
    if (excluded.isNotEmpty) {
      magazines = [
        for (final m in magazines)
          if (!excluded.contains(m.id)) m,
      ];
    }

    return _StandData(
      catalog: magazines,
      shelf: RecommendationService.buildInitialShelf(
        taste,
        magazines,
        daySeed: RecommendationService.todaySeed(),
      ),
      taste: taste,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is StandPageArgs) {
      _viewAllOnly = args.viewAll;
      _selectedTaste = args.selectedTaste;
    }
  }

  List<String> _chipLabels(List<String> taste) {
    if (taste.isEmpty) return _defaultTasteQueries.keys.toList();
    return taste.take(6).toList();
  }

  String? _resolvedSelectedTaste(List<String> labels) {
    if (labels.isEmpty) return null;
    if (_selectedTaste != null && labels.contains(_selectedTaste)) {
      return _selectedTaste;
    }
    return labels.first;
  }

  List<String> _basisFor(String? selected, List<String> taste) {
    if (selected == null) return taste;
    return _defaultTasteQueries[selected] ?? <String>[selected];
  }

  Future<void> _openMagazine(Magazine magazine, List<String> tasteBasis) async {
    await Navigator.pushNamed(
      context,
      '/discover/why',
      arguments: WhyIssueArgs(magazine: magazine, tasteBasis: tasteBasis),
    );
    if (!mounted) return;
    setState(() => _standFuture = _loadStand());
  }

  void _selectTaste(_StandData data, String label) {
    setState(() => _selectedTaste = label);
    final index = RecommendationService.focusIndexForTaste(data.shelf, label);
    if (index != null) _shelfController.animateToPage(index);
  }

  RecommendationListResult _resultFor(_StandData data, String? selected) {
    return RecommendationService.listForTaste(
      _basisFor(selected, data.taste),
      data.catalog,
      daySeed: RecommendationService.todaySeed(),
    );
  }

  String? _fallbackNotice(RecommendationListResult result) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LogzineTopBar(showBack: true, showBell: false),
            Expanded(
              child: FutureBuilder<_StandData>(
                future: _standFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.forest),
                    );
                  }
                  final labels = _chipLabels(data.taste);
                  final selected = _resolvedSelectedTaste(labels);
                  final result = _resultFor(data, selected);
                  if (_viewAllOnly) {
                    return _ViewAllList(
                      result: result,
                      labels: labels,
                      selectedTaste: selected,
                      onSelectTaste: (label) {
                        setState(() => _selectedTaste = label);
                      },
                      onOpen: (magazine) => _openMagazine(
                        magazine,
                        _basisFor(selected, data.taste),
                      ),
                    );
                  }
                  return _StandShelfView(
                    data: data,
                    labels: labels,
                    selectedTaste: selected,
                    fallbackNotice: _fallbackNotice(result),
                    controller: _shelfController,
                    onSelectTaste: (label) => _selectTaste(data, label),
                    onViewAll: () {
                      setState(() => _viewAllOnly = true);
                    },
                    onOpen: (magazine) => _openMagazine(
                      magazine,
                      _basisFor(selected, data.taste),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandShelfView extends StatelessWidget {
  const _StandShelfView({
    required this.data,
    required this.labels,
    required this.selectedTaste,
    required this.fallbackNotice,
    required this.controller,
    required this.onSelectTaste,
    required this.onViewAll,
    required this.onOpen,
  });

  final _StandData data;
  final List<String> labels;
  final String? selectedTaste;
  final String? fallbackNotice;
  final MagazineShelfController controller;
  final ValueChanged<String> onSelectTaste;
  final VoidCallback onViewAll;
  final ValueChanged<Magazine> onOpen;

  @override
  Widget build(BuildContext context) {
    if (data.shelf.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: _EmptyRecommendationCard(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PageTitleHeader(
            title: 'Today\'s stand',
            actionLabel: 'View all',
            onActionTap: onViewAll,
          ),
        ),
        const SizedBox(height: 18),
        MagazineShelf(
          magazines: data.shelf,
          controller: controller,
          showTodaysPick: true,
          onCenterTap: onOpen,
        ),
        const SizedBox(height: 12),
        const Center(child: ShelfSwipeHint()),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR TASTE', style: eyebrowStyle(color: AppColors.ink)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final label in labels)
                    TasteChip(
                      label: label,
                      selected: label == selectedTaste,
                      onTap: () => onSelectTaste(label),
                    ),
                ],
              ),
              if (fallbackNotice != null) ...[
                const SizedBox(height: 14),
                _FallbackNotice(message: fallbackNotice!),
              ],
              const SizedBox(height: 18),
              if (standCueForShelf(data.shelf) case final cue?)
                StandCueCard(info: cue, onTap: () => onOpen(cue.magazine)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewAllList extends StatelessWidget {
  const _ViewAllList({
    required this.result,
    required this.labels,
    required this.selectedTaste,
    required this.onSelectTaste,
    required this.onOpen,
  });

  final RecommendationListResult result;
  final List<String> labels;
  final String? selectedTaste;
  final ValueChanged<String> onSelectTaste;
  final ValueChanged<Magazine> onOpen;

  @override
  Widget build(BuildContext context) {
    final notice =
        result.kind == RecommendationMatchKind.fallback &&
            result.basis.isNotEmpty
        ? '${result.basis.first} 매거진은 아직 준비 중이에요.\n대신 가까운 취향의 매거진을 보여드릴게요.'
        : null;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: result.magazines.isEmpty ? 2 : result.magazines.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageTitleHeader(title: selectedTaste ?? 'All magazines'),
              const SizedBox(height: 18),
              Text('YOUR TASTE', style: eyebrowStyle(color: AppColors.ink)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final label in labels)
                    TasteChip(
                      label: label,
                      selected: label == selectedTaste,
                      onTap: () => onSelectTaste(label),
                    ),
                ],
              ),
              if (notice != null) ...[
                const SizedBox(height: 14),
                _FallbackNotice(message: notice),
              ],
            ],
          );
        }
        if (result.magazines.isEmpty) {
          return const _EmptyRecommendationCard();
        }
        final magazine = result.magazines[index - 1];
        return _MagazineListTile(
          magazine: magazine,
          tasteBasis: result.basis,
          fallback: result.kind == RecommendationMatchKind.fallback,
          onTap: () => onOpen(magazine),
        );
      },
    );
  }
}

class _MagazineListTile extends StatelessWidget {
  const _MagazineListTile({
    required this.magazine,
    required this.tasteBasis,
    required this.fallback,
    required this.onTap,
  });

  final Magazine magazine;
  final List<String> tasteBasis;
  final bool fallback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final matched = RecommendationService.matchedTags(tasteBasis, magazine);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 94,
                height: 126,
                child: Hero(
                  tag: magazineHeroTag(magazine),
                  child: MagazineCover(magazine: magazine),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magazine.title,
                      style: logoStyle(
                        size: 24,
                        weight: FontWeight.w600,
                        letterSpacingEm: 0.04,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      magazine.tagline,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.body,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      magazine.issue,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (fallback)
                          const _FallbackChip()
                        else
                          for (final tag in matched) _MatchedTag(label: tag),
                        if (!fallback && matched.isNotEmpty)
                          Text(
                            '${RecommendationService.matchPercent(tasteBasis, magazine)}% match',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text(
                          'Open issue',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.forest,
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

class _MatchedTag extends StatelessWidget {
  const _MatchedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 11, color: AppColors.forest),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackChip extends StatelessWidget {
  const _FallbackChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.wine.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.wine.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'nearby taste',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.wine,
        ),
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

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

class _EmptyRecommendationCard extends StatelessWidget {
  const _EmptyRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지금 취향에 딱 맞는 새 매거진을 찾는 중이에요.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '관심 키워드를 조금 더 추가하면 추천이 넓어져요.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
