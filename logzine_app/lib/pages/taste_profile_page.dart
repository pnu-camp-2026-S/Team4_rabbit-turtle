import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

/// 온보딩 3단계 — 분석된 취향 프로필.
class TasteProfilePage extends StatefulWidget {
  const TasteProfilePage({super.key});

  @override
  State<TasteProfilePage> createState() => _TasteProfilePageState();
}

class _TasteProfilePageState extends State<TasteProfilePage> {
  static const int _maxLength = 120;
  static const List<String> _tasteTags = [
    'Warm wood',
    'Quiet rooms',
    'Soft light',
    'Minimal objects',
    'Editorial mood',
  ];

  final TextEditingController _commentController = TextEditingController();
  int _commentLength = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
                        title: 'Your taste profile',
                        subtitle: "Here's what we found.",
                      ),
                      const SizedBox(height: 22),

                      // 취향 요약 카드 (콜라주 + 태그 + 한 줄 요약)
                      const _TasteCard(tags: _tasteTags),
                      const SizedBox(height: 24),

                      const Text(
                        'Refine with a comment',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 코멘트 입력 (우하단 글자수 카운터)
                      Stack(
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            maxLength: _maxLength,
                            onChanged: (text) =>
                                setState(() => _commentLength = text.length),
                            decoration: const InputDecoration(
                              hintText:
                                  'I want more modern studios and fewer '
                                  'rustic rooms',
                              counterText: '',
                              contentPadding: EdgeInsets.fromLTRB(
                                16, 14, 16, 30,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            bottom: 10,
                            child: Text(
                              '$_commentLength / $_maxLength',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      OnboardingPrimaryButton(
                        label: 'Update taste',
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('취향 프로필이 업데이트됐어요'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/main',
                          (route) => false,
                          arguments: 1, // 온보딩 완료 → 디스커버 탭
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Start recommendations'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사진 콜라주 + 취향 태그 + AI 한 줄 요약 카드.
class _TasteCard extends StatelessWidget {
  const _TasteCard({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 콜라주: 좌측 큰 사진 + 우측 두 장
          SizedBox(
            height: 210,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: NetworkPhoto(url: kMoodPhotos[0], radius: 10),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            NetworkPhoto(url: kMoodPhotos[1], radius: 10),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child:
                            NetworkPhoto(url: kMoodPhotos[2], radius: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 취향 태그 칩
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final tag in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFE6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // AI 한 줄 요약
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: AppColors.ink),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A calm editorial space with warm materials.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.body),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
