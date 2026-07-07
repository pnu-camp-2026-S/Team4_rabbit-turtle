import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/onboarding_widgets.dart';

/// 취향 대분류 하나 — 매거진 커버(사진) + 세부 태그.
class _Facet {
  const _Facet({
    required this.name,
    required this.caption,
    required this.photo,
    required this.tags,
  });

  final String name; // 음식
  final String caption; // FOOD
  final String photo; // 커버 사진
  final List<String> tags; // 세부 태그
}

/// 취향 트리 — 대분류 6개(가판대 커버), 각 대분류의 세부 태그.
const List<_Facet> _kFacets = [
  _Facet(
    name: '음식',
    caption: 'FOOD',
    photo: 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['카페', '디저트', '와인', '집밥', '파인다이닝', '로컬 맛집'],
  ),
  _Facet(
    name: '패션',
    caption: 'FASHION',
    photo: 'https://images.unsplash.com/photo-1483985988355-763728e1935b'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['미니멀', '빈티지', '스트릿', '디자이너 브랜드', '액세서리', '데일리룩'],
  ),
  _Facet(
    name: '공간',
    caption: 'SPACE',
    photo: 'https://images.unsplash.com/photo-1503602642458-232111445657'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인테리어', '가구', '호텔', '전시 공간', '동네 가게', '작업실'],
  ),
  _Facet(
    name: '여행',
    caption: 'TRAVEL',
    photo: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['도시 여행', '로컬', '숙소', '산책', '자연', '주말 여행'],
  ),
  _Facet(
    name: '예술',
    caption: 'ART',
    photo: 'https://images.unsplash.com/photo-1531913764164-f85c52e6e654'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['전시', '현대미술', '공예', '디자인', '일러스트', '사진'],
  ),
  _Facet(
    name: '음악',
    caption: 'MUSIC',
    photo: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745'
        '?auto=format&fit=crop&w=600&q=80',
    tags: ['인디', '재즈', '플레이리스트', '공연', '바이닐', '사운드트랙'],
  ),
];

/// 취향 직접 고르기 — 매거진 가판대 캐러셀로 대분류를 넘겨보고,
/// 대분류를 열면 아래에서 세부 취향 지면이 올라온다.
class TastePickerPage extends StatefulWidget {
  const TastePickerPage({super.key});

  @override
  State<TastePickerPage> createState() => _TastePickerPageState();
}

class _TastePickerPageState extends State<TastePickerPage>
    with SingleTickerProviderStateMixin {
  static const int _start = 2; // 가운데(공간)에서 시작

  final PageController _controller =
      PageController(viewportFraction: 0.62, initialPage: _start);

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _revealCurve =
      CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic);

  double _page = _start.toDouble();
  int _current = _start;
  bool _opened = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients && _controller.position.haveDimensions) {
        setState(() => _page = _controller.page ?? _page);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _reveal.dispose();
    super.dispose();
  }

  /// 가운데 커버를 탭 → 세부 태그 지면을 연다.
  void _open() {
    if (_opened) return;
    setState(() => _opened = true);
    _reveal.forward();
  }

  void _toggleTag(String tag) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _TopBar(),
              const SizedBox(height: 20),
              _Header(),
              const SizedBox(height: 12),
              // 가판대 + (열리면) 세부 태그가 함께 배치되는 영역
              Expanded(child: _buildStage()),
              _BottomAction(
                enabled: _selected.isNotEmpty,
                onNext: () {
                  // 온보딩 완료 → 디스커버 탭으로 (스택 초기화)
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                    arguments: 1,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 무대 — 닫힘: 세로로 긴 가판대가 중앙 / 열림: 가판대가 위로 올라가고
  /// 세부 태그가 바로 이어붙어 화면 아래 약 1/3만 차지.
  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight;
        const double gap = 16; // 커버 ↔ 태그 사이
        const double openTop = 6; // 열림 시 커버 상단 여백
        // 열림 시 태그 지면 시작점 = 화면 아래 약 1/3 지점.
        final double tagsTopOpen = h * 0.66;
        // 커버 블록(커버+점)은 그 위 공간을 채우도록 세로로 길게.
        final double blockH =
            (tagsTopOpen - openTop - gap).clamp(240.0, 380.0);
        final double carouselH = blockH - 18; // 점(12+6) 제외
        final double closedTop = ((h - blockH) / 2).clamp(0.0, h);

        return AnimatedBuilder(
          animation: _revealCurve,
          builder: (context, _) {
            final double v = _revealCurve.value;
            final double carouselTop = closedTop + (openTop - closedTop) * v;
            final double tagsTop = carouselTop + blockH + gap;
            return Stack(
              children: [
                // 세부 태그 지면 (커버 바로 아래에서 이어져 올라오며 페이드)
                Positioned(
                  top: tagsTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: v < 0.99,
                    child: Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, (1 - v) * 24),
                        child: _buildTags(),
                      ),
                    ),
                  ),
                ),
                // 가판대 캐러셀 (세로로 긴 커버)
                Positioned(
                  top: carouselTop,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SizedBox(height: carouselH, child: _buildCarousel()),
                      const SizedBox(height: 12),
                      _Dots(count: _kFacets.length, active: _current),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 매거진 가판대 캐러셀 ──────────────────────────────
  Widget _buildCarousel() {
    return PageView.builder(
      controller: _controller,
      itemCount: _kFacets.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (context, index) {
        final double t = (_page - index).abs().clamp(0.0, 1.0);
        final double scale = 1 - 0.12 * t;
        final double opacity = 1 - 0.42 * t;
        final bool isCenter = t < 0.5;
        return Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  if (isCenter) {
                    _open();
                  } else {
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: _FacetCover(
                  facet: _kFacets[index],
                  elevated: isCenter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 세부 태그 지면 (대분류 바뀌면 자연스럽게 교체) ──────────
  Widget _buildTags() {
    final facet = _kFacets[_current];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _TagSheet(
          key: ValueKey(facet.caption),
          facet: facet,
          selected: _selected,
          onToggle: _toggleTag,
        ),
      ),
    );
  }
}

/// 상단 바 — 뒤로가기 + 작은 라벨.
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back, size: 22, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '취향 고르기',
          style: logoStyle(
            size: 15,
            weight: FontWeight.w600,
            letterSpacingEm: 0.12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 헤더 — 한글 세리프 제목 + 회색 부제.
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '무엇에 마음이 머무나요',
          style: serifHeading(size: 25, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          '취향을 매거진처럼 넘겨보고, 가까운 장면을 열어보세요.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// 대분류 매거진 커버 — 사진 + 대분류명/영문 캡션.
class _FacetCover extends StatelessWidget {
  const _FacetCover({required this.facet, required this.elevated});

  final _Facet facet;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.28 : 0.14),
            blurRadius: elevated ? 22 : 12,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(url: facet.photo, radius: 0),
            // 하단 어두운 그라데이션 (라벨 가독성)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            // 라벨 (하단)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facet.caption,
                    style: logoStyle(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacingEm: 0.28,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    facet.name,
                    style: serifHeading(size: 22, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 캐러셀 위치 표시 점.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == active ? 16 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: i == active ? AppColors.sage : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}

/// 세부 태그 지면 — 카드/박스 없이 여백과 타이포로만 영역감.
class _TagSheet extends StatelessWidget {
  const _TagSheet({
    super.key,
    required this.facet,
    required this.selected,
    required this.onToggle,
  });

  final _Facet facet;
  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final count = facet.tags.where(selected.contains).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 캡션 (영문 트래킹)
        Text(
          '${facet.caption} NOTES',
          style: logoStyle(
            size: 10.5,
            weight: FontWeight.w600,
            letterSpacingEm: 0.28,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        // 섹션 제목 + 선택 개수
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${facet.name}에서 고르기',
              style: serifHeading(size: 19, color: AppColors.ink),
            ),
            const Spacer(),
            Text(
              count == 0 ? '' : '$count개 선택됨',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 태그 — soft-rect 라벨, 자연스러운 wrap
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final tag in facet.tags)
              _SoftTag(
                label: tag,
                selected: selected.contains(tag),
                onTap: () => onToggle(tag),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// soft-rect 라벨 — 사각형 실루엣 + 부드럽게 눌린 모서리(연속곡률).
/// 선택은 채움이 아니라 테두리·텍스트 톤으로만 표현.
class _SoftTag extends StatelessWidget {
  const _SoftTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: ShapeDecoration(
          // 선택: 채움 없음 / 미선택: 아주 옅은 off-white
          color: selected ? Colors.transparent : AppColors.sageSoft,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: selected ? AppColors.sage : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.sage : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 하단 액션 — 채운 버튼이 아니라 오른쪽 정렬 텍스트 + 화살표.
/// 선택 0개면 흐리게, 선택 후 muted green으로 활성화.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.enabled, required this.onNext});

  final bool enabled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final Color color = enabled ? AppColors.sage : AppColors.textMuted;
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: enabled ? onNext : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '다음',
                style: serifHeading(size: 17, color: color),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
