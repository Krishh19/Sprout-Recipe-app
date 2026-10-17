import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

class ScannerViewfinder extends StatefulWidget {
  final bool isAnalyzing;
  final Uint8List? capturedImageBytes;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  const ScannerViewfinder({
    super.key,
    required this.isAnalyzing,
    this.capturedImageBytes,
    this.onCameraTap,
    this.onGalleryTap,
  });

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _detectionController;

  @override
  void initState() {
    super.initState();

    // Laser scan beam: moves top to bottom and repeats
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOutSine),
    );

    // Subtle pulse for focus ring and scanning dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Dynamic detection rings animation during scanning
    _detectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    if (widget.isAnalyzing) {
      _laserController.repeat(reverse: true);
      _detectionController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ScannerViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing && !oldWidget.isAnalyzing) {
      _laserController.repeat(reverse: true);
      _detectionController.repeat();
    } else if (!widget.isAnalyzing && oldWidget.isAnalyzing) {
      _laserController.stop();
      _laserController.reset();
      _detectionController.stop();
      _detectionController.reset();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _pulseController.dispose();
    _detectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 226,
      decoration: BoxDecoration(
        color: isDark ? SproutColors.nightSurface : SproutColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFC8E6C9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF8FA486).withValues(alpha: 0.20),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer
            if (widget.isAnalyzing && widget.capturedImageBytes != null)
              Image.memory(
                widget.capturedImageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              Image.asset(
                SproutAssets.scannerFreshBackdrop,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: isDark
                      ? SproutColors.nightElevatedSurface
                      : SproutColors.sproutGreen.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 44,
                      color: SproutColors.sage,
                    ),
                  ),
                ),
              ),

            // 2. Dark Vignette Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.black.withValues(alpha: widget.isAnalyzing ? 0.32 : 0.42),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Analyzing-Only: Glowing Green Grid Overlay
            if (widget.isAnalyzing)
              CustomPaint(
                painter: _GridOverlayPainter(),
              ),

            // 4. Corner Brackets (Present in both states)
            CustomPaint(
              painter: _CornerBracketsPainter(
                glow: widget.isAnalyzing,
              ),
            ),

            // 5. Analyzing-Only: Animated Scanning Laser Beam & Sparkles
            if (widget.isAnalyzing) ...[
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LaserBeamPainter(
                      progress: _laserAnimation.value,
                    ),
                  );
                },
              ),

              // Scanning Status Pill Badge (Top Left)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xCC133118),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF69F0AE).withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF69F0AE),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scanning...',
                        style: SproutTypography.caption(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              // Sparkle stars
              Positioned(
                top: 40,
                right: 42,
                child: Image.asset(
                  SproutAssets.starSparkle,
                  width: 15,
                  height: 15,
                ),
              ),
              Positioned(
                bottom: 45,
                left: 45,
                child: Image.asset(
                  SproutAssets.starSparkle,
                  width: 13,
                  height: 13,
                ),
              ),

              // Animated Temporary Ingredient Detection Rings / Labels
              AnimatedBuilder(
                animation: _detectionController,
                builder: (context, _) {
                  final val = _detectionController.value;
                  // Detection 1: appears at 0.15 - 0.55
                  final show1 = val >= 0.15 && val <= 0.55;
                  final op1 = show1
                      ? (val < 0.25 ? (val - 0.15) * 10 : (val > 0.45 ? (0.55 - val) * 10 : 1.0)).clamp(0.0, 1.0)
                      : 0.0;

                  // Detection 2: appears at 0.50 - 0.90
                  final show2 = val >= 0.50 && val <= 0.90;
                  final op2 = show2
                      ? (val < 0.60 ? (val - 0.50) * 10 : (val > 0.80 ? (0.90 - val) * 10 : 1.0)).clamp(0.0, 1.0)
                      : 0.0;

                  return Stack(
                    children: [
                      if (op1 > 0)
                        Positioned(
                          top: 85,
                          left: 90,
                          child: Opacity(
                            opacity: op1,
                            child: _buildDetectionBadge('fresh produce'),
                          ),
                        ),
                      if (op2 > 0)
                        Positioned(
                          top: 115,
                          right: 80,
                          child: Opacity(
                            opacity: op2,
                            child: _buildDetectionBadge('spices & herbs'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],

            // 6. Idle-Only: Center Focus Ring & "Tap to scan ingredients"
            if (!widget.isAnalyzing) ...[
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionBadge(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF69F0AE),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF69F0AE),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xDD143818),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF69F0AE),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter that renders glowing neon green rounded corner brackets
class _CornerBracketsPainter extends CustomPainter {
  final bool glow;

  _CornerBracketsPainter({this.glow = false});

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 16.0;
    const arm = 28.0;
    const cornerRadius = 12.0;

    final basePaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: glow ? 0.7 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glow ? 5.5 : 4.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow ? 5.0 : 3.0);

    void drawCorner(Paint paint) {
      // Top Left
      final tlPath = Path()
        ..moveTo(margin, margin + arm)
        ..lineTo(margin, margin + cornerRadius)
        ..arcToPoint(
          Offset(margin + cornerRadius, margin),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(margin + arm, margin);
      canvas.drawPath(tlPath, paint);

      // Top Right
      final trPath = Path()
        ..moveTo(size.width - margin - arm, margin)
        ..lineTo(size.width - margin - cornerRadius, margin)
        ..arcToPoint(
          Offset(size.width - margin, margin + cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(size.width - margin, margin + arm);
      canvas.drawPath(trPath, paint);

      // Bottom Left
      final blPath = Path()
        ..moveTo(margin, size.height - margin - arm)
        ..lineTo(margin, size.height - margin - cornerRadius)
        ..arcToPoint(
          Offset(margin + cornerRadius, size.height - margin),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(margin + arm, size.height - margin);
      canvas.drawPath(blPath, paint);

      // Bottom Right
      final brPath = Path()
        ..moveTo(size.width - margin - arm, size.height - margin)
        ..lineTo(size.width - margin - cornerRadius, size.height - margin)
        ..arcToPoint(
          Offset(size.width - margin, size.height - margin - cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(size.width - margin, size.height - margin - arm);
      canvas.drawPath(brPath, paint);
    }

    drawCorner(glowPaint);
    drawCorner(basePaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

/// CustomPainter that renders a translucent neon green grid across the viewfinder
class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: 0.16)
      ..strokeWidth = 1.0;

    const spacing = 24.0;

    // Vertical grid lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter that renders an animated horizontal laser beam travelling vertically
class _LaserBeamPainter extends CustomPainter {
  final double progress;

  _LaserBeamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = 16.0 + progress * (size.height - 32.0);

    // Glowing diffused gradient band
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF69F0AE).withValues(alpha: 0.0),
          const Color(0xFF69F0AE).withValues(alpha: 0.25),
          const Color(0xFF69F0AE).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, y - 20, size.width, y + 20));

    canvas.drawRect(
      Rect.fromLTRB(0, y - 20, size.width, y + 20),
      glowPaint,
    );

    // Core laser line with bright glow
    final beamPaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), beamPaint);

    final whiteCorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), whiteCorePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserBeamPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
