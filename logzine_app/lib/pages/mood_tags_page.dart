import 'package:flutter/material.dart';

import '../models/taste_analysis.dart';
import '../services/photo_taste_analyzer.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show OnboardingHeader, OnboardingPrimaryButton, OnboardingTopBar, TasteChip;

import '../services/user_service.dart';
import 'taste_profile_page.dart';

class MoodTagsPageArgs {
  const MoodTagsPageArgs({required this.analysis, this.editMode = false});

  final TasteAnalysisResult analysis;
  final bool editMode;
}

/// 온보딩 2단계 — 분석 중 태그 선택.
class MoodTagsPage extends StatefulWidget {
  const MoodTagsPage({super.key});

  @override
  State<MoodTagsPage> createState() => _MoodTagsPageState();
}

class _MoodTagsPageState extends State<MoodTagsPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final Set<String> _selected = <String>{};
  TasteAnalysisResult? _analysis;
  bool _editMode = false;
  bool _argsApplied = false;
  bool _refining = false;

  void _toggle(String tag) {
    if (_refining) return;
    setState(() {
      _selected.contains(tag) ? _selected.remove(tag) : _selected.add(tag);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MoodTagsPageArgs) {
      _analysis = args.analysis;
      _editMode = args.editMode;
    } else {
      _analysis = args as TasteAnalysisResult? ?? TasteAnalysisResult.empty();
    }
    _selected.addAll(
      _analysis!.primaryKeywords.map((keyword) => keyword.label),
    );
    _argsApplied = true;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_refining) return;
    final analysis = _analysis ?? TasteAnalysisResult.empty();
    FocusScope.of(context).unfocus();
    setState(() => _refining = true);
    try {
      final profile = await PhotoTasteAnalyzer.refineProfile(
        analysis: analysis,
        confirmedLabels: _selected,
        feedback: _feedbackController.text,
      );
      try {
        await UserService().saveTasteTags(profile.displayTags);
      } catch (_) {} // 비로그인·오프라인이어도 온보딩은 계속
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/onboarding/profile',
        arguments: TasteProfilePageArgs(profile: profile, editMode: _editMode),
      );
    } on TasteAnalysisException {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('줄글 분석이 필요해요'),
          content: const Text('AI가 작성한 피드백을 분석하지 못했어요. 잠시 후 다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _refining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis ?? TasteAnalysisResult.empty();

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              OnboardingTopBar(editMode: _editMode),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const OnboardingHeader(
                        title: 'Choose while we read',
                        subtitle: '맞는 관심사 후보만 남겨주세요.',
                      ),
                      const SizedBox(height: 22),

                      // 분석 진행 카드
                      const _AnalyzingCard(),
                      const SizedBox(height: 18),

                      // 분석 중인 사진들 (마지막 장은 로딩 중 느낌)
                      Row(
                        children: [
                          for (int i = 0; i < analysis.photos.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 0.82,
                                child: Opacity(
                                  opacity: i == analysis.photos.length - 1
                                      ? 0.45
                                      : 1,
                                  child: _PhotoPreview(
                                    photo: analysis.photos[i],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      _KeywordGroup(
                        title: 'Representative candidates',
                        keywords: analysis.primaryKeywords,
                        selected: _selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: 20),
                      _KeywordGroup(
                        title: 'More signals',
                        keywords: analysis.secondaryKeywords,
                        selected: _selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: 20),

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
                                  'Photo taste note',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              analysis.summary,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: AppColors.body,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              analysis.recommendedQuestion,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        enabled: !_refining,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: true,
                        enableSuggestions: true,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: '예: 여행은 아니고 조용한 분위기가 좋아서 찍었어',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              OnboardingPrimaryButton(
                label: _refining ? 'Refining taste...' : 'Continue',
                onPressed: _continue,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final TastePhoto photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        photo.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class _KeywordGroup extends StatelessWidget {
  const _KeywordGroup({
    required this.title,
    required this.keywords,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<TasteKeyword> keywords;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
            for (final keyword in keywords)
              TasteChip(
                label: keyword.label,
                selected: selected.contains(keyword.label),
                onTap: () => onToggle(keyword.label),
              ),
          ],
        ),
      ],
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
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE8E5DE))),
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
