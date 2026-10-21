import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/sprout_haptics.dart';
import '../../planner/meal_planner_screen.dart';

/// Polished Empty State Card for the Weekly Planner on the Home Screen.
///
/// Features a hand-drawn colored-pencil illustration of Sprout with an open
/// weekly meal planner, wooden pencil, small ingredient doodles (carrot, tomato, mint),
/// warm yellow accents, and zero pink, strictly adhering to Sprout's botanical palette.
class SproutWeeklyPlannerCard extends StatelessWidget {
  final VoidCallback? onCustomTap;

  const SproutWeeklyPlannerCard({
    super.key,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    return SproutBouncyTap(
      onTap: () {
        SproutHaptics.medium();
        if (onCustomTap != null) {
          onCustomTap!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MealPlannerScreen(),
            ),
          );
        }
      },
      child: Semantics(
        button: true,
        label: 'Plan your week',
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Hand-Drawn Colored-Pencil Illustration Header
                SizedBox(
                  height: 78,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Warm cream/paper background with subtle texture
                      Container(
                        color: isDark
                            ? const Color(0xFF1E3528)
                            : const Color(0xFFF6F3EA),
                      ),

                      // Custom Painter: Open planner book, pencil, ingredients, botanical doodles
                      CustomPaint(
                        painter: _WeeklyPlannerIllustrationPainter(isDark: isDark),
                      ),

                      // Sprout Mascot sitting playfully next to the open planner
                      Positioned(
                        top: 10,
                        left: 14,
                        child: Image.asset(
                          SproutAssets.mascotIdle,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Subtle warm yellow decorative star
                      Positioned(
                        top: 8,
                        right: 24,
                        child: Image.asset(
                          SproutAssets.starSparkle,
                          width: 13,
                          height: 13,
                          color: SproutColors.butter,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Heading without subtext or separate button
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Plan your week',
                          style: GoogleFonts.fraunces(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? SproutColors.nightPrimaryInk
                                : SproutColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark
                            ? SproutColors.nightSecondaryInk
                            : SproutColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering a friendly, hand-drawn colored-pencil illustration:
/// open weekly planner calendar, yellow wooden pencil, carrot & tomato doodles,
/// and subtle botanical leaves. Avoids pink; uses warm cream, sage, yellow & terracotta.
class _WeeklyPlannerIllustrationPainter extends CustomPainter {
  final bool isDark;

  _WeeklyPlannerIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // -------------------------------------------------------------------------
    // 1. Open Weekly Planner / Calendar (Center-Right)
    // -------------------------------------------------------------------------
    final plannerLeft = size.width * 0.44;
    final plannerTop = 14.0;
    final plannerWidth = size.width * 0.48;
    final plannerHeight = 62.0;

    // Planner drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(plannerLeft + 2, plannerTop + 3, plannerWidth, plannerHeight),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // Left & Right Pages (Open notebook)
    final pagePaint = Paint()
      ..color = isDark ? const Color(0xFF243B2C) : const Color(0xFFFFFDF8);
    final pageBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF385A43) : const Color(0xFFE5DFD1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final plannerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(plannerLeft, plannerTop, plannerWidth, plannerHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(plannerRect, pagePaint);
    canvas.drawRRect(plannerRect, pageBorderPaint);

    // Center Spine / Binding Line
    final spineX = plannerLeft + (plannerWidth / 2);
    final spinePaint = Paint()
      ..color = isDark ? const Color(0xFF3F664C) : const Color(0xFFE2DAC8)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(spineX, plannerTop + 2),
      Offset(spineX, plannerTop + plannerHeight - 2),
      spinePaint,
    );

    // Soft sage bookmark ribbon hanging out from top
    final ribbonPaint = Paint()
      ..color = SproutColors.sage
      ..style = PaintingStyle.fill;
    final ribbonPath = Path()
      ..moveTo(spineX - 3, plannerTop)
      ..lineTo(spineX + 3, plannerTop)
      ..lineTo(spineX + 3, plannerTop + 14)
      ..lineTo(spineX, plannerTop + 11)
      ..lineTo(spineX - 3, plannerTop + 14)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Calendar / Day Rows on Left Page (Mon, Tue, Wed)
    final gridLinePaint = Paint()
      ..color = (isDark ? Colors.white : SproutColors.forestGreen)
          .withValues(alpha: isDark ? 0.15 : 0.20)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final leftPageLeft = plannerLeft + 6;
    final leftPageRight = spineX - 6;
    for (int i = 0; i < 3; i++) {
      final y = plannerTop + 14 + (i * 14.0);
      canvas.drawLine(Offset(leftPageLeft, y), Offset(leftPageRight, y), gridLinePaint);
      // Small checkbox on left of each line
      canvas.drawCircle(
        Offset(leftPageLeft + 3, y),
        1.5,
        Paint()..color = SproutColors.botanicalGreen.withValues(alpha: 0.6),
      );
    }

    // Calendar / Day Rows on Right Page (Thu, Fri, Sat)
    final rightPageLeft = spineX + 6;
    final rightPageRight = plannerLeft + plannerWidth - 6;
    for (int i = 0; i < 3; i++) {
      final y = plannerTop + 14 + (i * 14.0);
      canvas.drawLine(Offset(rightPageLeft, y), Offset(rightPageRight, y), gridLinePaint);
      canvas.drawCircle(
        Offset(rightPageLeft + 3, y),
        1.5,
        Paint()..color = SproutColors.botanicalGreen.withValues(alpha: 0.6),
      );
    }

    // -------------------------------------------------------------------------
    // 2. Hand-Drawn Wooden Yellow Pencil (Angled across bottom right)
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(plannerLeft + plannerWidth - 14, plannerTop + plannerHeight - 8);
    canvas.rotate(-0.55);

    // Pencil yellow wooden body
    final pencilBodyPaint = Paint()..color = SproutColors.butter;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -2.5, 32, 5), const Radius.circular(1.5)),
      pencilBodyPaint,
    );

    // Pencil shaved wood cone
    final pencilWoodPaint = Paint()..color = const Color(0xFFF3EEE3);
    final pencilWoodPath = Path()
      ..moveTo(16, -2.5)
      ..lineTo(22, 0)
      ..lineTo(16, 2.5)
      ..close();
    canvas.drawPath(pencilWoodPath, pencilWoodPaint);

    // Graphite lead tip
    final pencilLeadPaint = Paint()..color = const Color(0xFF2C3E35);
    final pencilLeadPath = Path()
      ..moveTo(20, -1.0)
      ..lineTo(22.5, 0)
      ..lineTo(20, 1.0)
      ..close();
    canvas.drawPath(pencilLeadPath, pencilLeadPaint);

    // Dark green end band (NO PINK eraser!)
    final pencilBandPaint = Paint()..color = SproutColors.botanicalGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -2.5, 3, 5), const Radius.circular(1)),
      pencilBandPaint,
    );
    canvas.restore();

    // -------------------------------------------------------------------------
    // 3. Small Ingredient Doodles
    // -------------------------------------------------------------------------
    // A. Tiny Carrot Doodle (Bottom center)
    final carrotX = plannerLeft - 8;
    final carrotY = plannerTop + plannerHeight - 12;
    final carrotPaint = Paint()..color = SproutColors.carrot;
    final carrotPath = Path()
      ..moveTo(carrotX, carrotY - 6)
      ..lineTo(carrotX + 5, carrotY - 6)
      ..lineTo(carrotX + 2.5, carrotY + 7)
      ..close();
    canvas.drawPath(carrotPath, carrotPaint);

    // Carrot leafy green top
    final carrotGreenPaint = Paint()
      ..color = SproutColors.botanicalGreen
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(carrotX + 2.5, carrotY - 6), Offset(carrotX, carrotY - 11), carrotGreenPaint);
    canvas.drawLine(Offset(carrotX + 2.5, carrotY - 6), Offset(carrotX + 2.5, carrotY - 12), carrotGreenPaint);
    canvas.drawLine(Offset(carrotX + 2.5, carrotY - 6), Offset(carrotX + 5, carrotY - 10), carrotGreenPaint);

    // B. Tiny Tomato Doodle (Top right edge)
    final tomatoX = plannerLeft + plannerWidth - 8;
    final tomatoY = plannerTop + 8;
    final tomatoPaint = Paint()..color = SproutColors.tomato;
    canvas.drawCircle(Offset(tomatoX, tomatoY), 4.5, tomatoPaint);
    // Green tomato calyx
    final calyxPaint = Paint()..color = SproutColors.botanicalGreen;
    canvas.drawCircle(Offset(tomatoX, tomatoY - 3.5), 1.2, calyxPaint);

    // C. Fresh Mint Leaf Doodle (Near mascot)
    final mintX = 66.0;
    final mintY = 46.0;
    final mintPaint = Paint()
      ..color = SproutColors.botanicalGreen
      ..style = PaintingStyle.fill;
    final mintPath = Path()
      ..moveTo(mintX, mintY)
      ..quadraticBezierTo(mintX + 5, mintY - 6, mintX + 11, mintY - 3)
      ..quadraticBezierTo(mintX + 6, mintY + 3, mintX, mintY);
    canvas.drawPath(mintPath, mintPaint);

    // -------------------------------------------------------------------------
    // 4. Subtle Botanical Leaves & Warm Yellow Sparkle Accents
    // -------------------------------------------------------------------------
    final leafPaint = Paint()
      ..color = SproutColors.sage.withValues(alpha: isDark ? 0.35 : 0.5)
      ..style = PaintingStyle.fill;

    // Small decorative leaf near top right of planner
    final leafPath = Path()
      ..moveTo(plannerLeft + 22, plannerTop - 2)
      ..quadraticBezierTo(plannerLeft + 28, plannerTop - 9, plannerLeft + 34, plannerTop - 4)
      ..quadraticBezierTo(plannerLeft + 28, plannerTop + 1, plannerLeft + 22, plannerTop - 2);
    canvas.drawPath(leafPath, leafPaint);

    // Warm butter-yellow dot sparkles
    final starPaint = Paint()..color = SproutColors.butter.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(plannerLeft + 14, plannerTop + 8), 1.8, starPaint);
    canvas.drawCircle(Offset(plannerLeft + plannerWidth - 2, plannerTop + 36), 1.5, starPaint);
    canvas.drawCircle(Offset(plannerLeft + 4, plannerTop + plannerHeight - 4), 1.6, starPaint);
  }

  @override
  bool shouldRepaint(covariant _WeeklyPlannerIllustrationPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
