import 'package:flutter/material.dart';
import '../../design/colors.dart';
import '../../design/motion.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';

/// Compact, editorial coach mark card for Sprout's spotlight tour.
///
/// Design contract:
/// - The Sprout mascot lives **in the header** as a small transparent
///   asset (~44px). There is intentionally NO large illustration panel.
/// - Card height is fully content-driven (`MainAxisSize.min`).
/// - Sprout design tokens only: cream surface, botanical green ink,
///   sage borders, existing radii/typography/motion.
class SproutCoachMark extends StatelessWidget {
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onDone;

  /// Per-step transparent Sprout mascot variation shown in the header.
  final String? imageAsset;

  const SproutCoachMark({
    super.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    this.onBack,
    required this.onSkip,
    required this.onDone,
    this.imageAsset,
  });

  bool get isLastStep => stepIndex >= totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: 'Feature guide: $title. Step ${stepIndex + 1} of $totalSteps.',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320, minWidth: 260),
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E261E) : SproutColors.surface,
          borderRadius: SproutRadii.card,
          border: Border.all(
            color: SproutColors.sage.withValues(alpha: isDark ? 0.4 : 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  SproutColors.primaryInk.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + small transparent mascot + close
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: SproutTypography.h3().copyWith(
                      fontSize: 20,
                      color: isDark ? Colors.white : SproutColors.primaryInk,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Small transparent mascot — no background container,
                // no fixed illustration area, aspect ratio preserved.
                Image.asset(
                  imageAsset ?? SproutAssets.mascotWave,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    SproutAssets.mascotWave,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : SproutColors.muted,
                  ),
                  tooltip: 'Skip tour',
                  onPressed: onSkip,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: SproutTypography.body(
                color: isDark
                    ? const Color(0xFFD0D7D0)
                    : SproutColors.secondaryInk,
              ).copyWith(fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 14),
            // Progress + navigation row
            Row(
              children: [
                // Step indicator dots (animated)
                Row(
                  children: List.generate(totalSteps, (index) {
                    final isActive = index == stepIndex;
                    return AnimatedContainer(
                      duration: SproutMotion.medium,
                      curve: SproutMotion.emphasized,
                      margin: const EdgeInsets.only(right: 5),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? SproutColors.sproutGreen
                            : SproutColors.sage
                                .withValues(alpha: isDark ? 0.5 : 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const Spacer(),

                // First step: Back is replaced by Skip. Later steps: Back.
                if (stepIndex > 0) ...[
                  TextButton(
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(44, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Back',
                      style: SproutTypography.caption(
                        color: isDark
                            ? const Color(0xFFB0B8B0)
                            : SproutColors.secondaryInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(44, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Skip',
                      style: SproutTypography.caption(
                        color: isDark ? Colors.white54 : SproutColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Next, or Done on the final step
                FilledButton(
                  onPressed: isLastStep ? onDone : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: SproutColors.sproutGreen,
                    foregroundColor: SproutColors.elevatedSurface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    minimumSize: const Size(70, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: SproutRadii.borderPill,
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastStep ? 'Done' : 'Next',
                        style: SproutTypography.caption(
                          color: SproutColors.elevatedSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isLastStep
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 14,
                        color: SproutColors.elevatedSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

