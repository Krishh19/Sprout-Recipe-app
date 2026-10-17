import 'package:flutter/material.dart';
import 'package:smooth_border/smooth_border.dart';

class SproutRadii {
  SproutRadii._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double pill = 999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));

  // Specific semantic radii (classic circular fallback)
  static const BorderRadius card = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius button = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius nav = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius scanner = BorderRadius.all(Radius.circular(28.0));

  // ---------------------------------------------------------------------------
  // SQUIRCLE CONTINUOUS CURVATURE SHAPES (0.6 Smoothing matches iOS & Figma)
  // ---------------------------------------------------------------------------

  /// Creates a continuous-curvature squircle border shape for cards.
  static SmoothRectangleBorder squircleCard({
    BorderSide side = BorderSide.none,
    double smoothing = 0.6,
  }) {
    return SmoothRectangleBorder(
      borderRadius: 24.0,
      smoothing: smoothing,
      side: side,
    );
  }

  /// Creates a continuous-curvature squircle border shape for buttons.
  static SmoothRectangleBorder squircleButton({
    BorderSide side = BorderSide.none,
    double smoothing = 0.6,
  }) {
    return SmoothRectangleBorder(
      borderRadius: 16.0,
      smoothing: smoothing,
      side: side,
    );
  }

  /// Creates a continuous-curvature squircle border shape for floating navigation.
  static SmoothRectangleBorder squircleNav({
    BorderSide side = BorderSide.none,
    double smoothing = 0.6,
  }) {
    return SmoothRectangleBorder(
      borderRadius: 32.0,
      smoothing: smoothing,
      side: side,
    );
  }

  /// Smooth squircle clipper for card media and image overlays.
  static SmoothRectangleClipper clipperCard({double smoothing = 0.6}) {
    return SmoothRectangleClipper(
      borderRadius: 24.0,
      smoothing: smoothing,
    );
  }

  /// Smooth squircle clipper for navigation pill blur containers.
  static SmoothRectangleClipper clipperNav({double smoothing = 0.6}) {
    return SmoothRectangleClipper(
      borderRadius: 32.0,
      smoothing: smoothing,
    );
  }

  /// Smooth squircle clipper for buttons.
  static SmoothRectangleClipper clipperButton({double smoothing = 0.6}) {
    return SmoothRectangleClipper(
      borderRadius: 16.0,
      smoothing: smoothing,
    );
  }
}
