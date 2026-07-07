import 'package:flutter/material.dart';

import '../models/magazine.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import 'discover_page.dart';
import 'library_page.dart';
import 'main_shell.dart';

/// 홈 — 오늘의 조용한 읽기.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _heroUrl =
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e'
      '?auto=format&fit=crop&w=1200&q=80';
  static const String _continueUrl =
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb'
      '?auto=format&fit=crop&w=400&q=80';

  (String, String) get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return ('Good morning, Min', 'A slow start with quiet pages.');
    }
    if (hour < 18) {
      return ('Good afternoon, Min', 'A short read between moments.');
    }
    return ('Good evening, Min', 'Picked for a quiet evening.');
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _greeting;

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const LogzineTopBar(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 인사말
                    Text(
                      title,
                      style: logoStyle(
                        size: 31,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // 오늘의 키워드
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [KeywordChip()],
                    ),
                    const SizedBox(height: 22),

                    // 이어 읽기
                    const _SectionLabel('Continue reading'),
                    const SizedBox(height: 10),
                    _ContinueReadingCard(coverUrl: _continueUrl),
                    const SizedBox(height: 26),

                    // 오늘의 픽
                    const _SectionLabel("Today's pick"),
                    const SizedBox(height: 10),
                    _TodaysPickCard(imageUrl: _heroUrl),
                    const SizedBox(height: 26),
                  ],
                ),
              ),

              // 새로 나온 매거진 (가로 스크롤)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: 'New on the stand',
                  onViewAll: () => MainShell.switchTab(context, 1),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: kMagazines.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/discover/why'),
                    child: SizedBox(
                      width: 128,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2E000000),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: MagazineCover(magazine: kMagazines[i]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 내 취향
                    Row(
                      children: [
                        const _SectionLabel('Your taste'),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pushNamed(
                              context, '/onboarding/profile',
                              arguments: 'edit'),
                          child: const Row(
                            children: [
                              Text(
                                'Refine',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forest,
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 16, color: AppColors.forest),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TasteChip(label: 'Warm wood', selected: true),
                        TasteChip(label: 'Quiet rooms', selected: false),
                        TasteChip(
                            label: 'Editorial mood', selected: false),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // 최근 하이라이트
                    const _SectionLabel('Your recent mark'),
                    const SizedBox(height: 10),
                    const _RecentMarkCard(),
                    const SizedBox(height: 24),
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

/// 섹션 라벨.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}

/// 이어 읽기 카드 — 표지 + 진행률 + 재개 버튼.
class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/reader'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 80,
                child: NetworkPhoto(url: coverUrl, radius: 8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiet Materials',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Studio Log · Issue 34',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                            child: ReadProgressBar(percent: 42)),
                        const SizedBox(width: 10),
                        Text(
                          '42%',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘의 픽 — 풀블리드 에디토리얼 히어로 카드.
class _TodaysPickCard extends StatelessWidget {
  const _TodaysPickCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/discover/why'),
      child: Container(
        height: 330,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkPhoto(url: imageUrl, radius: 0),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC1C1C1E), Color(0x00000000)],
                    stops: [0.0, 0.62],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 라벨
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12, color: AppColors.ink),
                          SizedBox(width: 6),
                          Text(
                            'Picked from your taste',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ROOM NOTE',
                      style: logoStyle(
                        size: 28,
                        weight: FontWeight.w600,
                        letterSpacingEm: 0.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A quiet life with things that last · Issue 28',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xE6FFFFFF)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/reader'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Start reading'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/discover/why'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text('Why this issue'),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ],
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

/// 최근 하이라이트 인용 카드.
class _RecentMarkCard extends StatelessWidget {
  const _RecentMarkCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/reader'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9C46A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“When light, texture, and proportion align, '
                      'the quiet becomes a language.”',
                      style: logoStyle(
                        size: 18,
                        weight: FontWeight.w500,
                        letterSpacingEm: 0.0,
                        color: AppColors.ink,
                      ).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Quiet Materials · p.4',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
