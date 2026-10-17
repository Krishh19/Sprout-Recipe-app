import 'package:flutter/material.dart';
import 'package:variable_blur/variable_blur.dart';

/// Reusable hero illustration widget for onboarding slides.
///
/// Blends Sprout's artisanal hero illustrations smoothly into the page canvas
/// through localized variable blur on the lower region, topped with a
/// theme-aware linear gradient ending in the exact page background color.
class SproutOnboardingHero extends StatelessWidget {
  /// Asset path of the onboarding illustration.
  final String imageAsset;

  /// Background color to dissolve into (resolves from active scaffold/canvas token).
  final Color backgroundColor;

  /// Height allocated to the hero illustration.
  final double height;

  /// Optional corner radius to preserve the intended silhouette (e.g. top corners).
  final BorderRadius? borderRadius;

  /// Focal alignment for the artwork, keeping mascot Sprout centered and in frame.
  final Alignment imageAlignment;

  /// Overall blur intensity for the variable blur effect.
  final double sigma;

  /// Fraction of the lower area where variable blur softens image details.
  final double blurBottom;

  /// Rendering quality for the variable blur fragment shader.
  final BlurQuality quality;

  /// Whether to apply variable blur (set to false for a pure gradient-only fallback).
  final bool enableBlur;

  /// Whether fragment shader requires Y coordinate flip (defaults to false for modern Flutter).
  final bool isYFlipNeed;

  const SproutOnboardingHero({
    super.key,
    required this.imageAsset,
    required this.backgroundColor,
    required this.height,
    this.borderRadius,
    this.imageAlignment = const Alignment(0, -0.18),
    this.sigma = 12.0,
    this.blurBottom = 0.40,
    this.quality = BlurQuality.medium,
    this.enableBlur = true,
    this.isYFlipNeed = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      imageAsset,
      fit: BoxFit.cover,
      alignment: imageAlignment,
      width: double.infinity,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: backgroundColor),
    );

    Widget heroIllustration;
    if (enableBlur) {
      heroIllustration = VariableBlur(
        sigma: sigma,
        blurSides: BlurSides.vertical(bottom: blurBottom),
        quality: quality,
        isYFlipNeed: isYFlipNeed,
        child: imageWidget,
      );
    } else {
      heroIllustration = imageWidget;
    }

    Widget heroStack = SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Variable Blur layer softening the lower portion of the illustration
          heroIllustration,

          // 2. Theme-aware gradient overlay ending in the exact page background
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0.0),
                      backgroundColor.withValues(alpha: 0.0),
                      backgroundColor.withValues(alpha: 0.28),
                      backgroundColor.withValues(alpha: 0.72),
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.38, 0.65, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: heroStack);
    }

    return heroStack;
  }
}

/// Convenience alias matching the illustrative implementation name
typedef OnboardingHero = SproutOnboardingHero;
