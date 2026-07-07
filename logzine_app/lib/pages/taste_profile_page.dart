import 'package:flutter/material.dart';

import '../models/taste_analysis.dart';
import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show OnboardingHeader, OnboardingTopBar;

/// 온보딩 3단계 — 분석된 취향 프로필.
class TasteProfilePage extends StatefulWidget {
  const TasteProfilePage({super.key});

  @override
  State<TasteProfilePage> createState() => _TasteProfilePageState();
}

class _TasteProfilePageState extends State<TasteProfilePage> {
  /// 메인 화면(홈·Archive의 Refine)에서 진입한 편집 모드 여부.
  bool _editMode = false;
  bool _argsApplied = false;
  TasteProfileDraft? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsApplied) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _editMode = args == 'edit';
      if (args is TasteProfileDraft) {
        _profile = args;
      }
      _argsApplied = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        _profile ??
        PhotoTasteAnalyzer.buildProfile(
          analysis: TasteAnalysisResult.empty(),
          confirmedLabels: const <String>{},
        );

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
                        title: 'Your taste profile',
                        subtitle: '확인한 후보만 취향 프로필에 반영했어요.',
                      ),
                      const SizedBox(height: 22),

                      // 취향 요약 카드 (콜라주 + 태그 + 한 줄 요약)
                      _TasteCard(profile: profile),
                      const SizedBox(height: 24),

                      if (!_editMode) ...[
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
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
                      ],
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
  const _TasteCard({required this.profile});

  final TasteProfileDraft profile;

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
                  child: _ProfilePhoto(
                    photo: profile.photos.isNotEmpty ? profile.photos[0] : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _ProfilePhoto(
                          photo: profile.photos.length > 1
                              ? profile.photos[1]
                              : profile.photos.firstOrNull,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ProfilePhoto(
                          photo: profile.photos.length > 2
                              ? profile.photos[2]
                              : profile.photos.firstOrNull,
                        ),
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
              for (final tag in profile.displayTags)
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 15, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.summary,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.body),
                ),
              ),
            ],
          ),
          if (profile.confirmedTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${profile.confirmedTags.length} confirmed signals · '
              '${profile.photoTags.length} photo candidates',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photo});

  final TastePhoto? photo;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const ColoredBox(color: AppColors.placeholder),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        photo!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
