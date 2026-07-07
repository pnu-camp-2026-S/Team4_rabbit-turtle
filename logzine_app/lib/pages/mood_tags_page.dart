import 'package:flutter/material.dart';

import '../models/mood_analysis.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

import '../services/user_service.dart';

/// 온보딩 2단계 — 분석 중 태그 선택.
class MoodTagsPage extends StatefulWidget {
  const MoodTagsPage({super.key});

  @override
  State<MoodTagsPage> createState() => _MoodTagsPageState();
}

class _MoodTagsPageState extends State<MoodTagsPage> {
  /// 태그 어휘 — AI 분석기와 공유하는 단일 출처.
  static const Map<String, List<String>> _groups = kMoodVocab;

  /// AI 분석 실패/미사용 시의 데모 기본값.
  static const List<String> _demoSuggested = [
    'Warm wood',
    'Soft light',
    'Quiet room',
  ];
  static const Set<String> _demoSelected = {
    'Calm',
    'Interior',
    'Wood',
    'Editorial',
    'Natural light',
  };

  MoodAnalysis? _analysis;
  MoodTagsArgs? _args;
  bool _argsApplied = false;

  Set<String> _selected = Set.of(_demoSelected);
  List<String> _suggested = _demoSuggested;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;

    // 업로드 화면에서 넘어온 사진 + AI 분석 결과 반영
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is MoodTagsArgs) {
      _args = args;
      final MoodAnalysis? analysis = args.analysis;
      if (analysis != null) {
        _analysis = analysis;
        if (analysis.tags.isNotEmpty) _selected = Set.of(analysis.tags);
        if (analysis.suggested.isNotEmpty) _suggested = analysis.suggested;
        // AI가 뽑은 자유 키워드는 처음부터 선택된 상태 = "자동으로 정리된 내 취향"
        _selected.addAll(_suggested);
      }
    }
  }

  /// 상단에 보여줄 사진들 — 첨부한 사진(bytes) 우선, 없으면 프리셋.
  List<Widget> _photoWidgets() {
    final List<Widget> photos = [
      if (_args != null) ...[
        for (final bytes in _args!.photoBytes)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        for (final url in _args!.photoUrls) NetworkPhoto(url: url),
      ],
    ];
    if (photos.isEmpty) {
      photos.addAll([for (final url in kMoodPhotos) NetworkPhoto(url: url)]);
    }
    return photos.take(4).toList();
  }

  void _toggle(String tag) {
    setState(() {
      _selected.contains(tag) ? _selected.remove(tag) : _selected.add(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const OnboardingTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const OnboardingHeader(
                        title: 'Choose while we read',
                        subtitle: 'Select tags that match your taste.',
                      ),
                      const SizedBox(height: 22),

                      // 분석 진행 카드
                      const _AnalyzingCard(),
                      const SizedBox(height: 18),

                      // 분석에 사용된 사진들 (사용자가 첨부한 사진 우선)
                      Builder(builder: (context) {
                        final photos = _photoWidgets();
                        return Row(
                          children: [
                            for (int i = 0; i < photos.length; i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 0.82,
                                  child: photos[i],
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 24),

                      // ★ AI가 사진에서 읽어낸 키워드 — 자동 정리된 내 취향 (주인공)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 15,
                                  color: AppColors.forest,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'From your photos',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '사진에서 읽어낸 키워드예요 — 탭해서 뺄 수 있어요',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final tag in _suggested)
                                  TasteChip(
                                    label: tag,
                                    selected: _selected.contains(tag),
                                    onTap: () => _toggle(tag),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 고정 어휘 태그 그룹 — 미세 조정용
                      for (final entry in _groups.entries) ...[
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final tag in entry.value)
                              TasteChip(
                                label: tag,
                                selected: _selected.contains(tag),
                                onTap: () => _toggle(tag),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              OnboardingPrimaryButton(
                label: 'Continue',
                onPressed: () async {
                  try {
                    await UserService().saveTasteTags(_selected.toList());
                  } catch (_) {} // 비로그인·오프라인이어도 온보딩은 계속
                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/onboarding/profile',
                    // AI가 생성한 취향 한 줄 요약을 프로필 화면에 전달
                    arguments: (_analysis?.summary.isNotEmpty ?? false)
                        ? _analysis!.summary
                        : null,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'Analyzing photos...' → 'Analysis complete ✓' 세그먼트 진행 바 카드.
class _AnalyzingCard extends StatefulWidget {
  const _AnalyzingCard();

  @override
  State<_AnalyzingCard> createState() => _AnalyzingCardState();
}

class _AnalyzingCardState extends State<_AnalyzingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _done = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 전체 진행(0~1)을 4구간으로 나눠 세그먼트가 순차적으로 차오르게.
  double _segFill(double t, int index) {
    const int count = 4;
    final double start = index / count;
    final double end = (index + 1) / count;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _done ? Icons.check_circle : Icons.auto_awesome,
                size: 16,
                color: _done ? AppColors.forest : AppColors.ink,
              ),
              const SizedBox(width: 10),
              Text(
                _done
                    ? 'Analysis complete — 태그를 확인해보세요'
                    : 'Analyzing photos...',
                style: TextStyle(
                  fontSize: 13.5,
                  color: _done ? AppColors.forest : AppColors.ink,
                  fontWeight: _done ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              children: [
                for (int i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    flex: const [5, 2, 2, 1][i],
                    child: _Segment(fill: _segFill(_controller.value, i)),
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

/// 진행 바 한 칸.
class _Segment extends StatelessWidget {
  const _Segment({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFFE8E5DE)),
            ),
            FractionallySizedBox(
              widthFactor: fill,
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.forest),
            ),
          ],
        ),
      ),
    );
  }
}
