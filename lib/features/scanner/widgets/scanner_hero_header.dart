import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

/// 4-point golden star sparkle matching ref.png
class SproutSparkle extends StatelessWidget {
  final double size;
  final Color color;

  const SproutSparkle({
    super.key,
    this.size = 16,
    this.color = const Color(0xFFE89A3C),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// CustomPainter that renders a smooth curved golden-orange brush underline
class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE89C33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.95,
        size.width - 2,
        size.height * 0.35,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScannerHeroHeader extends StatelessWidget {
  final bool isAnalyzing;

  const ScannerHeroHeader({
    super.key,
    required this.isAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isAnalyzing
                ? _buildAnalyzingHeader(maxWidth)
                : _buildIdleHeader(maxWidth),
          );
        },
      ),
    );
  }

  Widget _buildIdleHeader(double maxWidth) {
    final bool isCompact = maxWidth < 370;
    final double headlineSize = isCompact ? 25.0 : 27.0;
    final double mascotWidth = isCompact ? 90.0 : 98.0;
    final double mascotHeight = mascotWidth * (144.0 / 112.0);
    final double descWidth = (maxWidth - mascotWidth - 36).clamp(180.0, 220.0);

    return SizedBox(
      key: const ValueKey('hero_idle'),
      height: 156,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left Column: Headline, Underline, Description
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Line 1: "What's in your" + Gold Sparkle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'What\'s in your',
                      style: SproutTypography.handwritten(
                        fontSize: headlineSize,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        color: SproutColors.primaryInk,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SproutSparkle(size: 15),
                  ],
                ),
                const SizedBox(height: 2),
                // Line 2: "kitchen today?"
                Text(
                  'kitchen today?',
                  style: SproutTypography.handwritten(
                    fontSize: headlineSize,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    color: SproutColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 3),
                // Smooth golden curved brush underline
                CustomPaint(
                  size: const Size(135, 8),
                  painter: _UnderlinePainter(),
                ),
                const SizedBox(height: 8),
                // Description: 3 lines
                SizedBox(
                  width: descWidth,
                  child: Text(
                    'Take a photo or add ingredients and Sprout \nwill suggest tasty recipes\nfor you.',
                    style: SproutTypography.small(
                      color: SproutColors.secondaryInk,
                      fontWeight: FontWeight.w500,
                    ).copyWith(
                      fontSize: 13,
                      height: 1.32,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side: Mascot sitting flush on top of viewfinder card + Callout
          Positioned(
            right: 2,
            bottom: -20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mascot sitting with magnifying glass
                Image.asset(
                  SproutAssets.scanMascotSitting,
                  width: mascotWidth,
                  height: mascotHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 3),
                // Callout: "Scan Cook Enjoy" + Star Sparkle
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: 0.08,
                      child: Text(
                        'Scan\nCook\nEnjoy',
                        textAlign: TextAlign.center,
                        style: SproutTypography.handwritten(
                          fontSize: 13,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          color: SproutColors.primaryInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SproutSparkle(size: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingHeader(double maxWidth) {
    final bool isCompact = maxWidth < 370;
    final double headlineSize = isCompact ? 24.0 : 26.0;
    final double mascotWidth = isCompact ? 86.0 : 94.0;
    final double mascotHeight = mascotWidth * (128.0 / 105.0);
    final double subWidth = (maxWidth - mascotWidth - 36).clamp(180.0, 230.0);

    return SizedBox(
      key: const ValueKey('hero_analyzing'),
      height: 156,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left Column: Headline, Subtitle
          Positioned(
            left: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sprout is',
                  style: SproutTypography.handwritten(
                    fontSize: headlineSize,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    color: SproutColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'analyzing your ingredients',
                  style: SproutTypography.handwritten(
                    fontSize: isCompact ? 21.0 : 23.0,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    color: SproutColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: subWidth,
                  child: Text(
                    'Just a moment... turning your ingredients\ninto delicious possibilities!',
                    style: SproutTypography.small(
                      color: SproutColors.secondaryInk,
                      fontWeight: FontWeight.w500,
                    ).copyWith(
                      fontSize: 13,
                      height: 1.32,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mascot Peeking resting on top edge of scanner
          Positioned(
            right: 0,
            bottom: -2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  SproutAssets.scanMascotPeeking,
                  width: mascotWidth,
                  height: mascotHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 3),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SproutSparkle(size: 15),
                    const SizedBox(height: 6),
                    Transform.rotate(
                      angle: 0.06,
                      child: Text(
                        'Looking\nfor tasty\nideas...',
                        textAlign: TextAlign.center,
                        style: SproutTypography.handwritten(
                          fontSize: 12,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          color: SproutColors.primaryInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
