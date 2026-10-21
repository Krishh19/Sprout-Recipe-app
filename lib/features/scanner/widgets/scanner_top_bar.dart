import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

class ScannerTopBar extends StatelessWidget {
  final bool isAnalyzing;
  final VoidCallback? onCancel;

  const ScannerTopBar({
    super.key,
    required this.isAnalyzing,
    this.onCancel,
  });

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: SproutColors.sage.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Image.asset(
                  SproutAssets.scanMascotSitting,
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Sprout Scanner Works',
                        style: SproutTypography.h3(),
                      ),
                      Text(
                        'From countertop to delicious table',
                        style: SproutTypography.caption(
                          color: SproutColors.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStepRow(
              number: '1',
              title: 'Snap your ingredients',
              desc: 'Point your camera at vegetables, herbs, or pantry items.',
            ),
            const SizedBox(height: 14),
            _buildStepRow(
              number: '2',
              title: 'Instant smart detection',
              desc: 'Sprout AI identifies ingredients directly from your photo.',
            ),
            const SizedBox(height: 14),
            _buildStepRow(
              number: '3',
              title: 'Cook delicious meals',
              desc: 'Get curated recipes prioritizing what you already have.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SproutColors.sproutGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: SproutRadii.borderPill,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Got it!',
                  style: SproutTypography.bodyBold(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: SproutColors.sproutGreen,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: SproutTypography.smallBold(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SproutTypography.body(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: SproutTypography.small(
                  color: SproutColors.secondaryInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    return SafeArea(
      bottom: false,
      left: true,
      right: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sprout Wordmark in Fraunces Serif (Reference 3)
          Flexible(
            child: Text(
              'sprout',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fraunces(
                color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: 24,
              ),
            ),
          ),

          // Dynamic Right Button: "How it works?" or "✕ Cancel"
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isAnalyzing
                ? SproutBouncyTap(
                    key: const ValueKey('cancel_btn'),
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        borderRadius: SproutRadii.borderPill,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.4),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SproutColors.primaryInk.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: SproutColors.primaryInk,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Cancel',
                            style: SproutTypography.smallBold(
                              color: SproutColors.primaryInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SproutBouncyTap(
                    key: const ValueKey('how_it_works_btn'),
                    onTap: () => _showHowItWorks(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
                        borderRadius: SproutRadii.borderPill,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF284031)
                              : SproutColors.subtleBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 15,
                            color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'How it works?',
                            style: SproutTypography.smallBold(
                              color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
                            ).copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
}
