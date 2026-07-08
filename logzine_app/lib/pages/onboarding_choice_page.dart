import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart'
    show NetworkPhoto, OnboardingHeader, OnboardingTopBar, kMoodPhotos;

class OnboardingChoicePage extends StatelessWidget {
  const OnboardingChoicePage({super.key});

  static const String _keywordImage =
      'https://images.unsplash.com/photo-1497215728101-856f4ea42174'
      '?auto=format&fit=crop&w=900&q=80';

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
              const SizedBox(height: 18),
              const OnboardingHeader(
                title: 'Find your taste',
                subtitle: '취향을 찾는 방식을 먼저 골라주세요.',
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
                          imageUrl: kMoodPhotos[1],
                          icon: Icons.photo_camera_outlined,
                          height: compact ? 188 : 224,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/onboarding/upload',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ChoiceTile(
                          title: '키워드로 선택하기',
                          subtitle: '관심 있는 키워드를 직접 골라 추천 기준을 만들어요.',
                          imageUrl: _keywordImage,
                          icon: Icons.tune_rounded,
                          height: compact ? 188 : 224,
                          onTap: () => Navigator.pushNamed(context, '/taste'),
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
