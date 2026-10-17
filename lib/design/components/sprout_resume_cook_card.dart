import 'package:flutter/material.dart';
import '../../models/cook_session.dart';
import '../colors.dart';
import '../radii.dart';
import '../typography.dart';
import 'sprout_bouncy_tap.dart';

/// Prominent "pick up where you left off" card shown on Home when a
/// cooking session is still in progress.
class SproutResumeCookCard extends StatelessWidget {
  final CookSession session;
  final VoidCallback onResume;
  final VoidCallback? onDismiss;

  const SproutResumeCookCard({
    super.key,
    required this.session,
    required this.onResume,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = session.recipe.instructions.length;
    final step = (session.currentStep + 1).clamp(1, totalSteps == 0 ? 1 : totalSteps);
    final progress = totalSteps == 0 ? 0.0 : step / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SproutColors.sproutGreen, SproutColors.leaf],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: SproutRadii.card,
          boxShadow: [
            BoxShadow(
              color: SproutColors.sproutGreen.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SproutRadii.card,
            onTap: onResume,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CONTINUE COOKING',
                          style: SproutTypography.caption(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ).copyWith(letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          session.recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SproutTypography.bodyBold(color: Colors.white),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Step $step of $totalSteps',
                              style: SproutTypography.caption(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    Semantics(
                      button: true,
                      label: 'Dismiss resume cooking card',
                      child: SproutBouncyTap(
                        onTap: onDismiss,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}