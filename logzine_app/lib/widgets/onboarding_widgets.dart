import 'package:flutter/material.dart';

import '../theme.dart';
import 'logzine_logo.dart';
import 'motion_widgets.dart';

/// 온보딩 공용 무드 사진 세트 (소파 / 원목 의자 / 머그 / 책).
const List<String> kMoodPhotos = [
  'https://images.unsplash.com/photo-1555041469-a586c61ea9bc'
      '?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1503602642458-232111445657'
      '?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d'
      '?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1512820790803-83ca734da794'
      '?auto=format&fit=crop&w=600&q=80',
];

/// 온보딩 공용 뒤로가기 버튼 — 이전 화면으로 pop.
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.maybePop(context),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.arrow_back, size: 22, color: AppColors.ink),
      ),
    );
  }
}

/// 상단 바 — (뒤로가기) + 좌측 LOGZINE 워드마크, 우측 Skip.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key, this.onSkip, this.editMode = false});

  final VoidCallback? onSkip;

  /// 메인 화면에서 재진입한 편집 모드 — Skip을 숨긴다.
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    // 온보딩 흐름·편집 모드 모두, 돌아갈 화면이 있으면 뒤로가기를 보여준다.
    final bool canBack = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canBack) ...[
          const OnboardingBackButton(),
          const SizedBox(width: 8),
        ],
        const LogzineLogo(height: 24),
        const Spacer(),
        if (!editMode)
          TextButton(
            onPressed:
                onSkip ??
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                  arguments: 0, // 온보딩 완료 → Stand(홈) 탭
                ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Skip'),
          ),
      ],
    );
  }
}

/// 세리프 대제목 + 회색 부제목.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: logoStyle(
            size: 34,
            weight: FontWeight.w500,
            letterSpacingEm: 0.0,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// 모서리 둥근 네트워크 사진 (로딩/실패 시 웜 플레이스홀더).
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url, this.radius = 10});

  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: AppColors.placeholder),
        // 로딩 중에는 시머 자리표시자. 로드 완료 시 부드럽게 교체된다.
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const ShimmerBox(),
      ),
    );
  }
}

/// 선택형 태그 칩 — 선택 시 흰 배경 유지 + 딥그린 테두리.
class TasteChip extends StatelessWidget {
  const TasteChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.forest : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// 온보딩 화면 하단 딥그린 주 버튼.
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
