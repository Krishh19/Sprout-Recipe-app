import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../radii.dart';
import '../sprout_assets.dart';
import '../typography.dart';
import 'sprout_bouncy_tap.dart';

class SproutHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const SproutHeroCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: SproutRadii.card,
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: SproutRadii.card,
        child: Stack(
          children: [
            // Artisanal Kitchen Background Banner
            Positioned.fill(
              child: Image.asset(
                SproutAssets.bannerKitchen,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),

            // Soft Dark Forest Gradient Scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF14241B).withValues(alpha: 0.90),
                      const Color(0xFF14241B).withValues(alpha: 0.65),
                      const Color(0xFF14241B).withValues(alpha: 0.15),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Inspiration Tag with Frosted Glass
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.butter.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: SproutColors.butter.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'DAILY INSPIRATION',
                          style: SproutTypography.caption(
                            color: SproutColors.butter,
                            fontWeight: FontWeight.w800,
                          ).copyWith(letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'REAL INGREDIENTS.\nBRIGHTER DAYS.',
                    style: SproutTypography.h2(
                      color: Colors.white,
                    ).copyWith(
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SproutBouncyTap(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: SproutRadii.borderPill,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore recipes',
                            style: SproutTypography.smallBold(
                              color: SproutColors.sproutGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: SproutColors.sproutGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
