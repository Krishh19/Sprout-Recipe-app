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
        ? (isDark ? const Color(0xFF244834) : SproutColors.forestGreen)
        : (isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory);

    final fg = isSelected
        ? Colors.white
        : (isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary);

    final borderColor = isSelected
        ? (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
        : (isDark ? const Color(0xFF284031) : SproutColors.subtleBorder);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
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
                  color: (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
                      .withValues(alpha: isDark ? 0.30 : 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 4,
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
