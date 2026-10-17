import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import 'sprout_button.dart';

class SproutEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final String? imageAsset;
  final double imageHeight;
  final EdgeInsetsGeometry? padding;

  const SproutEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.eco_rounded,
    this.imageAsset,
    this.imageHeight = 130.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageAsset != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - val) * 12),
                      child: Opacity(
                        opacity: val,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    imageAsset!,
                    height: imageHeight,
                    fit: BoxFit.contain,
                  ),
                )
              else
                // Organic illustrated circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: SproutColors.sage.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SproutColors.sage.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 44,
                      color: SproutColors.sproutGreen,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: SproutTypography.h3(),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: SproutTypography.body(color: SproutColors.secondaryInk),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                SproutButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  height: 48,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
