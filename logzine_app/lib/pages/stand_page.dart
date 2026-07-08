import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../services/magazine_service.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/magazine_shelf.dart';
import '../widgets/onboarding_widgets.dart';
import 'why_issue_page.dart';

/// 가판대 목록 데이터 — 추천순 매거진 + 사용자 취향(일치 태그 표시용).
class _StandData {
  const _StandData({required this.magazines, required this.taste});

  final List<Magazine> magazines;
  final List<String> taste;
}

enum _RecommendationMode { direct, fallback, empty }

class _StandResult {
  const _StandResult({
    required this.magazines,
    required this.mode,
    required this.matchBasis,
  });

  final List<Magazine> magazines;
  final _RecommendationMode mode;
  final List<String> matchBasis;

  bool get isFallback => mode == _RecommendationMode.fallback;
  bool get isEmpty => mode == _RecommendationMode.empty;
}

class StandPage extends StatefulWidget {
  const StandPage({super.key});

  @override
  State<StandPage> createState() => _StandPageState();
}

class _StandPageState extends State<StandPage> {
  static const int _maxStandMagazines = 6;
  late Future<_StandData> _standFuture = _loadStand();
  String? _selectedTaste;
  bool _argsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _selectedTaste = args.trim();
    }
  }

  /// 매거진을 취향∩태그 점수 순으로 정렬해 목록을 만든다.
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
    } catch (_) {
      // 비로그인 — 개인화 없이 진행
    }

    // "Not for me"로 제외한 매거진은 목록에서 뺀다
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

    return _StandData(magazines: ranked, taste: taste);
  }

  List<String> _tasteLabels(List<String> taste) => taste.take(6).toList();

  String? _resolvedTaste(List<String> labels) {
    final selected = _selectedTaste;
    if (selected != null && selected.trim().isNotEmpty) return selected;
    return labels.isEmpty ? null : labels.first;
  }

  _StandResult _standResult(_StandData data, String? selectedTaste) {
    if (selectedTaste != null) {
      final direct = RecommendationService.matchingOnly(
        <String>[selectedTaste],
        data.magazines,
        daySeed: RecommendationService.todaySeed(),
      );
      if (direct.isNotEmpty) {
        return _StandResult(
          magazines: direct,
          mode: _RecommendationMode.direct,
          matchBasis: <String>[selectedTaste],
        );
      }
      final fallback = RecommendationService.fallbackForKeyword(
        selectedTaste,
        data.magazines,
        daySeed: RecommendationService.todaySeed(),
      );
      if (fallback.isNotEmpty) {
        return _StandResult(
          magazines: fallback,
          mode: _RecommendationMode.fallback,
          matchBasis: RecommendationService.relatedFallbackTags(selectedTaste),
        );
      }
      return const _StandResult(
        magazines: [],
        mode: _RecommendationMode.empty,
        matchBasis: [],
      );
    }
    final ranked = RecommendationService.rank(
      data.taste,
      data.magazines,
      daySeed: RecommendationService.todaySeed(),
    ).take(_maxStandMagazines).toList();
    return _StandResult(
      magazines: ranked,
      mode: ranked.isEmpty
          ? _RecommendationMode.empty
          : _RecommendationMode.direct,
      matchBasis: data.taste,
    );
  }

  Future<void> _openMagazine(
    Magazine magazine, {
    List<String>? tasteBasis,
  }) async {
    await Navigator.pushNamed(
      context,
      '/discover/why',
      arguments: WhyIssuePageArgs(magazine: magazine, tasteBasis: tasteBasis),
    );
    if (!mounted) return;
    setState(() {
      _standFuture = _loadStand();
    });
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
                  final magazines =
                      snapshot.data?.magazines ?? const <Magazine>[];
                  final taste = snapshot.data?.taste ?? const <String>[];
                  final data = snapshot.data;
                  final tasteLabels = _tasteLabels(taste);
                  final selectedTaste = _resolvedTaste(tasteLabels);
                  final result = data == null
                      ? _StandResult(
                          magazines: magazines.take(6).toList(),
                          mode: _RecommendationMode.direct,
                          matchBasis: taste,
                        )
                      : _standResult(data, selectedTaste);
                  final visibleMagazines = result.magazines;
                  final activeTaste = result.matchBasis;
                  final noticeCount = result.isFallback || result.isEmpty
                      ? 1
                      : 0;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount:
                        visibleMagazines.length +
                        (tasteLabels.isEmpty ? 0 : 1) +
                        noticeCount,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (tasteLabels.isNotEmpty && index == 0) {
                        return _TasteFilterBar(
                          labels: tasteLabels,
                          selected: selectedTaste,
                          onSelected: (label) {
                            setState(() => _selectedTaste = label);
                          },
                        );
                      }
                      final shelfIndex = tasteLabels.isEmpty ? 0 : 1;
                      final noticeIndex = shelfIndex;
                      if (result.isFallback && index == noticeIndex) {
                        return _FallbackNotice(keyword: selectedTaste);
                      }
                      if (result.isEmpty && index == noticeIndex) {
                        return _EmptyKeywordResult(keyword: selectedTaste);
                      }
                      final listOffset =
                          (tasteLabels.isEmpty ? 0 : 1) + noticeCount;
                      final magazineIndex = index - listOffset;
                      final magazine = visibleMagazines[magazineIndex];
                      final matched = RecommendationService.matchedTags(
                        activeTaste,
                        magazine,
                      );
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () =>
                              _openMagazine(magazine, tasteBasis: activeTaste),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      // 추천 근거 — 내 취향과 겹치는 태그 + 일치율
                                      if (matched.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            for (final tag in matched)
                                              _MatchedTag(label: tag),
                                            Text(
                                              result.isFallback
                                                  ? 'nearby taste'
                                                  : '${RecommendationService.matchPercent(activeTaste, magazine)}% match',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                    },
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

class _TasteFilterBar extends StatelessWidget {
  const _TasteFilterBar({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR TASTE', style: eyebrowStyle(color: AppColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final label in labels)
              TasteChip(
                label: label,
                selected: label == selected,
                onTap: () => onSelected(label),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyKeywordResult extends StatelessWidget {
  const _EmptyKeywordResult({required this.keyword});

  final String? keyword;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 28,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            keyword == null
                ? '추천할 매거진이 아직 없어요'
                : '"$keyword" 취향에 맞는 매거진이 아직 준비되지 않았어요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '관심 키워드를 조금 더 추가하면 추천이 넓어져요.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.keyword});

  final String? keyword;

  @override
  Widget build(BuildContext context) {
    final label = keyword ?? '선택한 키워드';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label 매거진은 아직 준비 중이에요.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '대신 가까운 취향의 매거진을 골라봤어요.',
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

/// "내 취향과 일치" 태그 칩 — 추천 근거를 시각화한다.
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
