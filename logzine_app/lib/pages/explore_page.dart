import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logzine_logo.dart';

/// claude.ai/design "탐색 홈 v2" 시안을 Flutter로 옮긴 매거진 탐색 화면.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _Masthead(),
                    _SectionHeader(
                      title: '지금 취향에 가장 가까운 매거진',
                      subtitle: '당신의 취향을 분석해 선별했어요',
                      titleSize: 19,
                    ),
                    _HeroCard(),
                    _SectionHeader(
                      title: '같은 결의 추천',
                      subtitle: '비슷한 취향의 매거진이에요',
                      titleSize: 17,
                      inline: true,
                    ),
                    _SimilarPicks(),
                    _SectionHeader(
                      title: '이 발행사가 만든 다른 매거진',
                      titleSize: 17,
                    ),
                    _PublisherCard(),
                    _RefineCard(),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const _BottomTabBar(),
          ],
        ),
      ),
    );
  }
}

// ── 상단 마스트헤드 (로고 + 검색 + 세그먼트 탭) ──────────────────────────

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LogzineLogo(height: 34),
                    const SizedBox(height: 4),
                    const Text(
                      '닮아 있는 취향, 정제된 매거진',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.22,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications_none_rounded,
                  size: 22, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 16),
          // 검색창
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('태그, 발행사 검색',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 세그먼트 탭
          Row(
            children: const [
              _SegmentTab(label: '탐색', active: true),
              _SegmentTab(label: '라이브러리', active: false),
            ],
          ),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.ink : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── 섹션 헤더 ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.titleSize = 17,
    this.inline = false,
  });

  final String title;
  final String? subtitle;
  final double titleSize;
  final bool inline; // true면 제목·부제를 한 줄에 나란히

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(title, style: serifHeading(size: titleSize));
    final subtitleWidget = subtitle == null
        ? null
        : Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: inline && subtitleWidget != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                titleWidget,
                const SizedBox(width: 8),
                subtitleWidget,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 4),
                  subtitleWidget,
                ],
              ],
            ),
    );
  }
}

// ── 히어로 카드 ──────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1C1C1E),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 표지 + 그라데이션 오버레이
            SizedBox(
              width: 172,
              height: 260,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _CoverPlaceholder(label: '표지 이미지'),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 40, 14, 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x8C1C1C1E)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Open Room',
                              style: logoStyle(
                                size: 24,
                                weight: FontWeight.w500,
                                letterSpacingEm: 0.02,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 4),
                          const Text(
                            'Vol. 58 / 2024 Spring',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Open Room',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('발행사',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Text('Open Room Studio',
                        style: TextStyle(fontSize: 12, color: AppColors.body)),
                    const SizedBox(height: 12),
                    const Text(
                      '공간감 있는 인테리어와 조용한 브랜드 스토리 중심',
                      style: TextStyle(
                          fontSize: 12, height: 1.6, color: AppColors.body),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        _HeroAction(icon: Icons.bookmark_border, label: '저장'),
                        SizedBox(width: 18),
                        _HeroAction(icon: Icons.favorite_border, label: '좋아요'),
                        SizedBox(width: 18),
                        _HeroAction(
                            icon: Icons.notifications_none, label: '알림'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('읽기 시작'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.body),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.body)),
      ],
    );
  }
}

// ── 같은 결의 추천 (3열 그리드) ──────────────────────────────────────────

class _SimilarPicks extends StatelessWidget {
  const _SimilarPicks();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(child: _PickCard(name: 'Apartamento', vol: 'Vol. 33')),
          SizedBox(width: 10),
          Expanded(child: _PickCard(name: 'CEREAL', vol: 'Vol. 24')),
          SizedBox(width: 10),
          Expanded(child: _PickCard(name: 'nice things.', vol: 'Vol. 75')),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.name, required this.vol});

  final String name;
  final String vol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            const _CoverPlaceholder(label: '표지', height: 130, radius: 8),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bookmark_border,
                    size: 14, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(vol,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── 발행사 카드 ──────────────────────────────────────────────────────────

class _PublisherCard extends StatelessWidget {
  const _PublisherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'OPEN\nROOM',
              textAlign: TextAlign.center,
              style: logoStyle(
                  size: 10, weight: FontWeight.w600, letterSpacingEm: 0.08)
                  .copyWith(height: 1.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Open Room Studio',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(
                  '공간과 브랜드, 그리고 사람이 만나는 순간을 기록합니다.',
                  style: TextStyle(
                      fontSize: 11, height: 1.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('발행사 팔로우'),
                ),
              ),
              const SizedBox(height: 4),
              const Text('1,204명이 팔로우 중',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 취향 조정 카드 ───────────────────────────────────────────────────────

class _RefineCard extends StatelessWidget {
  const _RefineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('원하는 결을 조금 더 알려주세요', style: serifHeading(size: 16)),
          const SizedBox(height: 3),
          const Text('써 주신 문장을 분석해 추천에 반영해요',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          // 입력 상자
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: const [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.textSecondary),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '예: 조용한 공간, 절제된 사진, 브랜드 철학이 느껴지는 글을 더 보고 싶어요',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('0/200',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('추천 취향 조정하기'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 탭바 ────────────────────────────────────────────────────────────

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const _TabItem(icon: Icons.home_outlined, label: '피드'),
          const _TabItem(
              icon: Icons.article_outlined, label: '매거진', active: true),
          _TabItem(
            icon: Icons.collections_bookmark_outlined,
            label: '내 서재',
            onTap: () => Navigator.pushNamed(context, '/mypage'),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            if (active) ...[
              const SizedBox(height: 3),
              Container(width: 28, height: 2, color: AppColors.ink),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 이미지 자리 (표지 placeholder) ───────────────────────────────────────

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({
    required this.label,
    this.height,
    this.radius = 0,
  });

  final String label;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              size: 20, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
