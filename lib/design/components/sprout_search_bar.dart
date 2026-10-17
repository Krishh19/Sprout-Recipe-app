import 'package:flutter/material.dart';
import '../colors.dart';
import '../radii.dart';
import '../typography.dart';

class SproutSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const SproutSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onClear,
    this.hintText = 'Search recipes or ingredients',
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.borderPill,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.28),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        style: SproutTypography.body(),
        cursorColor: SproutColors.sproutGreen,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: SproutTypography.body(color: SproutColors.muted),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: SproutColors.primaryInk,
            size: 22,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller != null && controller!.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: SproutColors.muted,
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller!.clear();
                    onClear?.call();
                    onChanged?.call('');
                  },
                ),
              if (onFilterTap != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    color: SproutColors.sproutGreen,
                    tooltip: 'Search filters',
                    onPressed: onFilterTap,
                  ),
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
