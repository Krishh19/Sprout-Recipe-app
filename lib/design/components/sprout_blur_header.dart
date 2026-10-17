import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors.dart';

class SproutBlurHeader extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final Color? backgroundColor;
  final bool showBottomBorder;
  final EdgeInsetsGeometry padding;

  const SproutBlurHeader({
    super.key,
    required this.child,
    this.blurSigma = 18.0,
    this.backgroundColor,
    this.showBottomBorder = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = backgroundColor ?? SproutColors.canvas;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor.withValues(alpha: 0.94),
                baseColor.withValues(alpha: 0.82),
                baseColor.withValues(alpha: 0.65),
              ],
            ),
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: SproutColors.sage.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Progressive blur header that transitions from transparent to frosted blur
/// with a soft ambient scroll shadow as the user scrolls content upwards.
class SproutProgressiveBlurHeader extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final double maxBlur;
  final double scrollThreshold;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const SproutProgressiveBlurHeader({
    super.key,
    required this.child,
    this.scrollController,
    this.maxBlur = 20.0,
    this.scrollThreshold = 36.0,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
  });

  @override
  State<SproutProgressiveBlurHeader> createState() =>
      _SproutProgressiveBlurHeaderState();
}

class _SproutProgressiveBlurHeaderState
    extends State<SproutProgressiveBlurHeader> {
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant SproutProgressiveBlurHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null) return;
    final offset = widget.scrollController!.hasClients
        ? widget.scrollController!.offset
        : 0.0;
    final progress = (offset / widget.scrollThreshold).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.01) {
      setState(() => _scrollProgress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.backgroundColor ?? SproutColors.canvas;
    final currentBlur = widget.maxBlur * _scrollProgress;

    Widget content = Container(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.15 + (0.75 * _scrollProgress)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withValues(alpha: 0.20 + (0.75 * _scrollProgress)),
            baseColor.withValues(alpha: 0.10 + (0.65 * _scrollProgress)),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: SproutColors.sage.withValues(alpha: 0.25 * _scrollProgress),
            width: 1.0,
          ),
        ),
        boxShadow: _scrollProgress > 0.05
            ? [
                BoxShadow(
                  color: SproutColors.primaryInk
                      .withValues(alpha: 0.06 * _scrollProgress),
                  blurRadius: 16 * _scrollProgress,
                  offset: Offset(0, 4 * _scrollProgress),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (_scrollProgress > 0.01) {
      content = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: currentBlur, sigmaY: currentBlur),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A scroll wrapper that automatically captures scroll events from its child
/// and displays a progressive gradient blur & ambient scroll shadow at the top.
class SproutScrollShadowWrapper extends StatefulWidget {
  final Widget child;
  final double topOffset;
  final double shadowHeight;

  const SproutScrollShadowWrapper({
    super.key,
    required this.child,
    this.topOffset = 0.0,
    this.shadowHeight = 24.0,
  });

  @override
  State<SproutScrollShadowWrapper> createState() =>
      _SproutScrollShadowWrapperState();
}

class _SproutScrollShadowWrapperState extends State<SproutScrollShadowWrapper> {
  double _scrollProgress = 0.0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final offset = notification.metrics.pixels;
      final progress = (offset / 32.0).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.01) {
        setState(() => _scrollProgress = progress);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          widget.child,
          if (_scrollProgress > 0.01)
            Positioned(
              top: widget.topOffset,
              left: 0,
              right: 0,
              height: widget.shadowHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _scrollProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SproutColors.canvas.withValues(alpha: 0.85),
                          SproutColors.canvas.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
