import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors.dart';

/// Creates a luxury progressive blur and gradient scrim overlay,
/// smoothly melting hero imagery into the background canvas or card surface.
class SproutProgressiveBlur extends StatelessWidget {
  /// Total height of the progressive blur transition zone.
  final double height;

  /// The solid color to dissolve into (defaults to dynamic `SproutColors.canvas`).
  final Color? blendColor;

  /// Optional child rendered atop the progressive blur area.
  final Widget? child;

  /// Whether the blend progresses from top to bottom (true) or bottom to top (false).
  final bool topToBottom;

  const SproutProgressiveBlur({
    super.key,
    this.height = 140,
    this.blendColor,
    this.child,
    this.topToBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = blendColor ?? SproutColors.canvas;

    final beginAlignment = topToBottom ? Alignment.topCenter : Alignment.bottomCenter;
    final endAlignment = topToBottom ? Alignment.bottomCenter : Alignment.topCenter;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Band 1: Subtle initial softening blur
          Positioned(
            top: topToBottom ? height * 0.25 : 0,
            bottom: topToBottom ? 0 : height * 0.25,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Band 2: Medium depth blur
          Positioned(
            top: topToBottom ? height * 0.50 : 0,
            bottom: topToBottom ? 0 : height * 0.50,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Band 3: Deep atmospheric blur
          Positioned(
            top: topToBottom ? height * 0.75 : 0,
            bottom: topToBottom ? 0 : height * 0.75,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Progressive non-linear gradient scrim overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: beginAlignment,
                end: endAlignment,
                stops: const [0.0, 0.25, 0.55, 0.82, 1.0],
                colors: [
                  targetColor.withValues(alpha: 0.0),
                  targetColor.withValues(alpha: 0.20),
                  targetColor.withValues(alpha: 0.58),
                  targetColor.withValues(alpha: 0.90),
                  targetColor,
                ],
              ),
            ),
          ),

          ?child,
        ],
      ),
    );
  }
}
