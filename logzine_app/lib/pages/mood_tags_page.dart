import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

/// 온보딩 2단계 — 분석 중 태그 선택.
class MoodTagsPage extends StatefulWidget {
  const MoodTagsPage({super.key});

  @override
  State<MoodTagsPage> createState() => _MoodTagsPageState();
}

class _MoodTagsPageState extends State<MoodTagsPage> {
  static const Map<String, List<String>> _groups = {
    'Mood': ['Calm', 'Warm', 'Minimal', 'Sensory'],
    'Space': ['Interior', 'Studio', 'Living', 'Wood'],
    'Style': ['Editorial', 'Natural light', 'Objects', 'Books'],
  };

  static const List<String> _suggested = [
    'Warm wood',
    'Soft light',
    'Quiet room',
  ];

  final Set<String> _selected = {
    'Calm',
    'Interior',
    'Wood',
    'Editorial',
    'Natural light',
  };

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

                      // 분석 중인 사진들 (마지막 장은 로딩 중 느낌)
                      Row(
                        children: [
                          for (int i = 0; i < kMoodPhotos.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 0.82,
                                child: Opacity(
                                  opacity: i == kMoodPhotos.length - 1
                                      ? 0.45
                                      : 1,
                                  child: NetworkPhoto(url: kMoodPhotos[i]),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 태그 그룹
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

                      // 사진에서 추천된 태그
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
                                  color: AppColors.ink,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Suggested from photos',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              OnboardingPrimaryButton(
                label: 'Continue',
                onPressed: () =>
                    Navigator.pushNamed(context, '/onboarding/profile'),
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
