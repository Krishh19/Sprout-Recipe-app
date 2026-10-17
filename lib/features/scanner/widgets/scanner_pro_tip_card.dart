import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/radii.dart';
import '../../../design/typography.dart';

class ScannerProTipCard extends StatelessWidget {
  const ScannerProTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4E8),
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: const Color(0xFFC5E1C5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lightbulb Icon with gentle circle background
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF2E653A),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Pro Tip Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro tip',
                  style: SproutTypography.body(
                    fontWeight: FontWeight.w700,
                    color: SproutColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'For best results, keep ingredients well lit and in focus.',
                  style: SproutTypography.small(
                    color: SproutColors.secondaryInk,
                    fontWeight: FontWeight.w500,
                  ).copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Cursive Kalam Accent: "Good food happens here! ♡"
          Transform.rotate(
            angle: -0.08,
            child: Text(
              'Good\nfood\nhappens\nhere!\n♡',
              textAlign: TextAlign.center,
              style: SproutTypography.handwritten(
                fontSize: 12.5,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E653A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
