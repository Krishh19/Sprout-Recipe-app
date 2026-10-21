import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';
import 'sprout_scanner_overlay.dart';

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

  @override
  void initState() {
    super.initState();

    // Laser scan beam: moves top to bottom and repeats during analysis
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOutSine),
    );

    // Subtle pulse for active status indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isAnalyzing) {
      _laserController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ScannerViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing && !oldWidget.isAnalyzing) {
      _laserController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    } else if (!widget.isAnalyzing && oldWidget.isAnalyzing) {
      _laserController.stop();
      _laserController.reset();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 236,
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
            // 1. Background Image Layer: Captured photo when analyzing, else clean preview backdrop
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

            // 2. Dark Vignette Gradient for high contrast on guides
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.16),
                    Colors.transparent,
                    Colors.black.withValues(alpha: widget.isAnalyzing ? 0.38 : 0.44),
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

            // 4. Unified Symmetrical Scanner Corner Brackets
            const SproutScannerOverlay(
              isAnalyzing: true,
              margin: 18.0,
              armLength: 28.0,
              cornerRadius: 14.0,
              strokeWidth: 3.2,
            ),

            // 5. Analyzing State: Animated Laser Beam & Status Pill
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xE6133118),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF69F0AE).withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.30),
                        blurRadius: 10,
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
                              width: 8,
                              height: 8,
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
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing ingredients with AI...',
                        style: SproutTypography.caption(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.3, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 6. Idle State: Clean, concise guidance inside overlay's safe area
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.center_focus_strong_rounded,
                          color: Color(0xFF69F0AE),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Point at ingredients',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SproutTypography.caption(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ).copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
