import 'package:flutter/material.dart';

/// Reusable Sprout Scanner Overlay with 4 perfectly symmetrical, unified corner brackets.
///
/// Fixes previous geometry inversion bugs where bottom brackets arched outwards.
/// Maintains Sprout's botanical green accent with optional laser glow when scanning.
class SproutScannerOverlay extends StatelessWidget {
  final bool isAnalyzing;
  final double margin;
  final double armLength;
  final double cornerRadius;
  final double strokeWidth;
  final Color bracketColor;
  final Widget? child;

  const SproutScannerOverlay({
    super.key,
    this.isAnalyzing = false,
    this.margin = 16.0,
    this.armLength = 28.0,
    this.cornerRadius = 14.0,
    this.strokeWidth = 3.2,
    this.bracketColor = const Color(0xFF69F0AE),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SproutScannerCornerPainter(
        glow: isAnalyzing,
        margin: margin,
        arm: armLength,
        cornerRadius: cornerRadius,
        strokeWidth: strokeWidth,
        color: bracketColor,
      ),
      child: child,
    );
  }
}

/// Symmetrical CustomPainter that renders 4 matching corner brackets with identical geometry.
class SproutScannerCornerPainter extends CustomPainter {
  final bool glow;
  final double margin;
  final double arm;
  final double cornerRadius;
  final double strokeWidth;
  final Color color;

  const SproutScannerCornerPainter({
    this.glow = false,
    this.margin = 16.0,
    this.arm = 28.0,
    this.cornerRadius = 14.0,
    this.strokeWidth = 3.2,
    this.color = const Color(0xFF69F0AE),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: glow ? 0.75 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glow ? strokeWidth + 2.5 : strokeWidth + 1.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow ? 5.0 : 2.5);

    void drawCorners(Paint paint) {
      // 1. Top-Left Corner
      final tlPath = Path()
        ..moveTo(margin, margin + arm)
        ..lineTo(margin, margin + cornerRadius)
        ..arcToPoint(
          Offset(margin + cornerRadius, margin),
          radius: Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(margin + arm, margin);
      canvas.drawPath(tlPath, paint);

      // 2. Top-Right Corner
      final trPath = Path()
        ..moveTo(size.width - margin - arm, margin)
        ..lineTo(size.width - margin - cornerRadius, margin)
        ..arcToPoint(
          Offset(size.width - margin, margin + cornerRadius),
          radius: Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(size.width - margin, margin + arm);
      canvas.drawPath(trPath, paint);

      // 3. Bottom-Right Corner (Fixed clockwise sweep)
      final brPath = Path()
        ..moveTo(size.width - margin, size.height - margin - arm)
        ..lineTo(size.width - margin, size.height - margin - cornerRadius)
        ..arcToPoint(
          Offset(size.width - margin - cornerRadius, size.height - margin),
          radius: Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(size.width - margin - arm, size.height - margin);
      canvas.drawPath(brPath, paint);

      // 4. Bottom-Left Corner (Fixed clockwise sweep)
      final blPath = Path()
        ..moveTo(margin + arm, size.height - margin)
        ..lineTo(margin + cornerRadius, size.height - margin)
        ..arcToPoint(
          Offset(margin, size.height - margin - cornerRadius),
          radius: Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(margin, size.height - margin - arm);
      canvas.drawPath(blPath, paint);
    }

    drawCorners(glowPaint);
    drawCorners(basePaint);
  }

  @override
  bool shouldRepaint(covariant SproutScannerCornerPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.color != color ||
        oldDelegate.margin != margin ||
        oldDelegate.arm != arm ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
