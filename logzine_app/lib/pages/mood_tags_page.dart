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

/// 'Analyzing photos...' + 세그먼트 진행 바 카드.
class _AnalyzingCard extends StatelessWidget {
  const _AnalyzingCard();

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
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.ink),
              SizedBox(width: 10),
              Text(
                'Analyzing photos...',
                style: TextStyle(fontSize: 13.5, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 첫 세그먼트만 그린으로 차오르는 애니메이션
              Expanded(
                flex: 5,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => _Segment(
                    fill: value,
                    fillColor: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(flex: 2, child: _Segment(fill: 0)),
              const SizedBox(width: 6),
              const Expanded(flex: 2, child: _Segment(fill: 0)),
              const SizedBox(width: 6),
              const Expanded(flex: 1, child: _Segment(fill: 0)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 진행 바 한 칸.
class _Segment extends StatelessWidget {
  const _Segment({required this.fill, this.fillColor = AppColors.forest});

  final double fill;
  final Color fillColor;

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
              child: ColoredBox(color: fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
