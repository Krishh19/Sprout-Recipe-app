import 'package:flutter/material.dart';
import '../colors.dart';
import '../radii.dart';
import '../sprout_assets.dart';
import '../typography.dart';
import 'sprout_bouncy_tap.dart';

class SproutIngredientChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final Widget? leading;

  const SproutIngredientChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDeleted,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? SproutColors.sproutGreen : SproutColors.surface;
    final fg = isSelected ? SproutColors.elevatedSurface : SproutColors.primaryInk;
    final border = isSelected
        ? Border.all(color: SproutColors.sproutGreen, width: 1.2)
        : Border.all(color: SproutColors.sage.withValues(alpha: 0.35), width: 1.0);

    // Auto-resolve illustrated icon if leading is not explicitly provided
    final resolvedIconAsset = leading == null ? SproutIngredientAssets.resolve(label) : null;

    final chipContent = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SproutRadii.borderPill,
        border: border,
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: SproutRadii.borderPill,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 5),
                ] else if (resolvedIconAsset != null) ...[
                  Image.asset(
                    resolvedIconAsset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: SproutTypography.small(
                    color: fg,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return SproutBouncyTap(
      onTap: onTap,
      child: chipContent,
    );
  }
}
