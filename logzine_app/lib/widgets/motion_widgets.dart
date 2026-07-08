import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 이미지 로딩 자리의 은은한 시머 — 밋밋한 단색 박스 대신 크림 톤이
/// 부드럽게 스윕한다. 색은 토큰만 사용(placeholder ↔ screen)해 브랜드 톤 유지.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.radius = 0});

  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // 하이라이트 밴드를 좌→우로 통과시킨다.
          final double slide = -1.5 + 3.0 * _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  AppColors.placeholder,
                  AppColors.screen,
                  AppColors.placeholder,
                ],
                stops: const [0.35, 0.5, 0.65],
                transform: _SlideTransform(slide),
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

/// 그라디언트 밴드를 가로로 이동시키는 변환 (시머 스윕용).
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// 자식이 처음 나타날 때 아래에서 페이드+슬라이드로 등장.
/// 리스트에 [delay]를 인덱스별로 조금씩 주면 계단식(staggered) 등장이 된다.
/// State가 유지되는 동안 재생은 1회뿐이라 스크롤·탭 전환에 다시 튀지 않는다.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 14,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  /// 인덱스 기반 계단식 지연 — 앞쪽 [cap]개까지만 지연을 늘리고 그 뒤로는
  /// 고정(긴 리스트에서 화면 밖 항목이 과도하게 늦게 뜨는 것을 방지).
  static Duration stagger(int index, {int cap = 6, int stepMs = 55}) {
    final int steps = index < cap ? index : cap;
    return Duration(milliseconds: steps * stepMs);
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 누르면 살짝 눌리는 촉각 반응. 탭 자체는 소비하지 않으므로(Listener 사용)
/// 자식의 기존 InkWell/onTap과 물결 효과가 그대로 동작한다. 스크롤로 손가락이
/// 움직이면 눌림을 즉시 해제해 스크롤 중 눌린 채 남지 않는다.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerMove: (_) => _set(false),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 숫자가 0에서 목표값까지 부드럽게 올라가는 텍스트. 값이 처음 정해질 때
/// 한 번(또는 데이터 로드로 값이 바뀔 때마다) 카운트업한다.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 850),
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}

/// 히어로/표지 이미지에 아주 느린 줌·드리프트(켄번즈)를 얹어 고급 잡지의
/// 깊이감을 준다. [child]는 보통 NetworkPhoto 같은 큰 이미지.
class KenBurnsPhoto extends StatefulWidget {
  const KenBurnsPhoto({
    super.key,
    required this.child,
    this.maxScale = 1.08,
    this.duration = const Duration(seconds: 16),
  });

  final Widget child;
  final double maxScale;
  final Duration duration;

  @override
  State<KenBurnsPhoto> createState() => _KenBurnsPhotoState();
}

class _KenBurnsPhotoState extends State<KenBurnsPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final double t = _curve.value;
          final double scale = 1.0 + (widget.maxScale - 1.0) * t;
          return Transform.translate(
            offset: Offset(-6.0 * t, 4.0 * t),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
