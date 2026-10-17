import 'package:flutter/material.dart';
import '../colors.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';

class SproutFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final String? emoji;

  const SproutFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final bg = isSelected
        ? (isDark ? const Color(0xFF244838) : const Color(0xFF1A1A1A))
        : (isDark ? SproutColors.nightElevatedSurface : Colors.white);
    final fg = isSelected ? Colors.white : SproutColors.primaryInk;
    final borderColor = isSelected
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF1A1A1A))
        : (isDark ? SproutColors.sage.withValues(alpha: 0.35) : const Color(0xFFE5E7EB));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SproutRadii.borderPill,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isDark ? const Color(0xFF4ADE80) : Colors.black)
                      .withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: SproutRadii.borderPill,
          onTap: () {
            SproutHaptics.selection();
            onSelected();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: SproutTypography.small(
                    color: fg,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
