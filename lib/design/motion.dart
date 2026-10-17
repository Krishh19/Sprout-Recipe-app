import 'package:flutter/material.dart';

/// Sprout motion system — one place for every duration & curve.
///
/// All timings automatically scale to 40% when the platform's
/// "disable animations" accessibility setting is on.
class SproutMotion {
  SproutMotion._();

  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  // Curves
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve bounce = Curves.easeOutBack;

  /// Honors the OS "reduce motion" accessibility setting.
  static Duration scaled(BuildContext context, Duration duration) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration(milliseconds: (duration.inMilliseconds * 0.4).round());
    }
    return duration;
  }
}

/// Staggered entrance: fades in while sliding up slightly.
///
/// Use [index] to stagger sibling entrances by 50ms each.
class SproutFadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final Offset beginOffset;

  const SproutFadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = SproutMotion.slow,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.beginOffset = const Offset(0, 0.05),
  });

  @override
  State<SproutFadeSlideIn> createState() => _SproutFadeSlideInState();
}

class _SproutFadeSlideInState extends State<SproutFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: SproutMotion.entrance,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(curved);

    final delay = widget.staggerDelay * widget.index.clamp(0, 8);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
