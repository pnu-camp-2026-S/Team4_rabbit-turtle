import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show NetworkPhoto, OnboardingHeader, OnboardingTopBar;

class OnboardingChoicePage extends StatelessWidget {
  const OnboardingChoicePage({super.key});

  static const String _photoImage =
      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32'
      '?auto=format&fit=crop&w=900&q=80';
  static const String _keywordImage =
      'https://images.unsplash.com/photo-1455390582262-044cdead277a'
      '?auto=format&fit=crop&w=900&q=80';

  @override
  Widget build(BuildContext context) {
    final editMode = ModalRoute.of(context)?.settings.arguments == 'edit';

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              OnboardingTopBar(editMode: editMode),
              const SizedBox(height: 18),
              OnboardingHeader(
                title: editMode ? 'Refine your taste' : 'Find your taste',
                subtitle: editMode
                    ? '새로 고른 키워드가 기존 취향을 교체해요.'
                    : '취향을 찾는 방식을 먼저 골라주세요.',
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 560;
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _ChoiceTile(
                          title: '사진으로 내 취향 분석하기',
                          subtitle: '좋아하는 사진을 올리고 분위기와 관심사를 추출해요.',
                          imageUrl: _photoImage,
                          icon: Icons.photo_camera_outlined,
                          height: compact ? 188 : 224,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/onboarding/upload',
                            arguments: editMode ? 'edit' : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ChoiceTile(
                          title: '키워드로 선택하기',
                          subtitle: '관심 있는 키워드를 직접 골라 추천 기준을 만들어요.',
                          imageUrl: _keywordImage,
                          icon: Icons.tune_rounded,
                          height: compact ? 188 : 224,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/taste',
                            arguments: editMode
                                ? 'replace'
                                : 'onboarding-replace',
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.height,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData icon;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkPhoto(url: imageUrl, radius: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppColors.forest, size: 21),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
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
