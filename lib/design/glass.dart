import 'dart:ui';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'components/sprout_bouncy_tap.dart';
import 'radii.dart';
import 'sprout_haptics.dart';

/// Painter that draws a continuous gradient border along a rounded rectangle.
class GlassBorderPainter extends CustomPainter {
  final double strokeWidth;
  final Radius radius;
  final Gradient gradient;

  const GlassBorderPainter({
    required this.strokeWidth,
    required this.radius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GlassBorderPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.gradient != gradient;
  }
}

/// Core Glassmorphic Card supporting BackdropFilter, squircle continuous curvature,
/// and dual specular refraction gradient borders.
class SproutGlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Border? border;
  final Gradient? borderGradient;
  final double borderWidth;
  final bool useSquircle;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const SproutGlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurSigma = 20.0,
    this.backgroundColor,
    this.backgroundGradient,
    this.border,
    this.borderGradient,
    this.borderWidth = 1.2,
    this.useSquircle = false,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? SproutRadii.card;

    Widget content = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CustomPaint(
          foregroundPainter: borderGradient != null
              ? GlassBorderPainter(
                  strokeWidth: borderWidth,
                  radius: effectiveRadius.topLeft,
                  gradient: borderGradient!,
                )
              : null,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundGradient == null
                  ? (backgroundColor ?? SproutColors.glassBackground)
                  : null,
              gradient: backgroundGradient,
              borderRadius: effectiveRadius,
              border: borderGradient == null
                  ? (border ??
                      Border.all(
                        color: SproutColors.glassBorder,
                        width: borderWidth,
                      ))
                  : null,
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: SproutColors.primaryInk.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = SproutBouncyTap(
        onTap: onTap,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// Circular frosted glass button (e.g. 'X' close, '...' more, '🛒' cart, '📅' plan).
class SproutGlassCircleButton extends StatelessWidget {
  final Widget? icon;
  final IconData? iconData;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? tooltip;
  final double blurSigma;

  const SproutGlassCircleButton({
    super.key,
    this.icon,
    this.iconData,
    this.size = 44.0,
    this.iconSize = 20.0,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.tooltip,
    this.blurSigma = 16.0,
  }) : assert(icon != null || iconData != null, 'Provide either icon or iconData');

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white;
    final effectiveBg = backgroundColor ?? SproutColors.glassSmokedMedium;

    Widget button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveBg,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: icon ??
              Icon(
                iconData,
                size: iconSize,
                color: effectiveIconColor,
              ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return SproutBouncyTap(
      scaleFactor: 0.92,
      onTap: () {
        SproutHaptics.light();
        onTap?.call();
      },
      child: button,
    );
  }
}

/// Floating frosted status badge pill (e.g., "📅 Choose when to make it", "❤️ Added to Favorites").
class SproutGlassBadgePill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? backgroundColor;
  final double blurSigma;

  const SproutGlassBadgePill({
    super.key,
    required this.text,
    this.icon,
    this.leading,
    this.onTap,
    this.textColor,
    this.backgroundColor,
    this.blurSigma = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveBg = backgroundColor ?? SproutColors.glassSmokedMedium;

    Widget pill = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 15, color: effectiveTextColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      pill = SproutBouncyTap(
        scaleFactor: 0.96,
        onTap: () {
          SproutHaptics.light();
          onTap?.call();
        },
        child: pill,
      );
    }

    return pill;
  }
}

/// Translucent frosted glass stepper capsule `[ -  4  + ]`.
class SproutGlassStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final double height;
  final String? suffix;

  const SproutGlassStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 24,
    this.height = 36.0,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: SproutColors.glassSmokedMedium,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Minus button
              SproutBouncyTap(
                onTap: value > min
                    ? () {
                        SproutHaptics.selection();
                        onChanged(value - 1);
                      }
                    : null,
                child: Container(
                  width: height - 8,
                  height: height - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value > min
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > min ? Colors.white : Colors.white38,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Value label
              Text(
                suffix != null ? '$value $suffix' : '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              // Plus button
              SproutBouncyTap(
                onTap: value < max
                    ? () {
                        SproutHaptics.selection();
                        onChanged(value + 1);
                      }
                    : null,
                child: Container(
                  width: height - 8,
                  height: height - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value < max
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: value < max ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating glass action dock containing 5 quick actions (Save, Instructions, Plan, Grocery, Favorite).
class SproutGlassDock extends StatelessWidget {
  final bool isSaved;
  final bool isFavorite;
  final VoidCallback onSaveTap;
  final VoidCallback onInstructionsTap;
  final VoidCallback onPlanTap;
  final VoidCallback onGroceryTap;
  final VoidCallback onFavoriteTap;

  const SproutGlassDock({
    super.key,
    required this.isSaved,
    required this.isFavorite,
    required this.onSaveTap,
    required this.onInstructionsTap,
    required this.onPlanTap,
    required this.onGroceryTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: SproutRadii.squircleNav(),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipPath(
          clipper: SproutRadii.clipperNav(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 62,
              decoration: ShapeDecoration(
                shape: SproutRadii.squircleNav(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x9928231E),
                    Color(0x80181512),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDockItem(
                    icon: isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: 'Save',
                    isActive: isSaved,
                    onTap: onSaveTap,
                  ),
                  _buildDockItem(
                    icon: Icons.menu_book_rounded,
                    tooltip: 'Instructions',
                    isActive: false,
                    onTap: onInstructionsTap,
                  ),
                  _buildDockItem(
                    icon: Icons.calendar_month_outlined,
                    tooltip: 'Plan',
                    isActive: false,
                    onTap: onPlanTap,
                  ),
                  _buildDockItem(
                    icon: Icons.shopping_bag_outlined,
                    tooltip: 'Grocery',
                    isActive: false,
                    onTap: onGroceryTap,
                  ),
                  _buildDockItem(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    tooltip: 'Favorite',
                    isActive: isFavorite,
                    activeColor: SproutColors.tomato,
                    onTap: onFavoriteTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = isActive
        ? (activeColor ?? SproutColors.glassIconActive)
        : SproutColors.glassIconInactive;

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: SproutBouncyTap(
          scaleFactor: 0.90,
          onTap: () {
            SproutHaptics.light();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Translucent frosted glass segmented selector track (e.g. Breakfast, Lunch, Dinner, Snack).
class SproutGlassSegmentedTrack<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  const SproutGlassSegmentedTrack({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
          child: Row(
            children: items.map((item) {
              final isSelected = item == selectedItem;
              return Expanded(
                child: SproutBouncyTap(
                  onTap: () {
                    SproutHaptics.selection();
                    onSelected(item);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SproutColors.glassWarmAmber
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: SproutColors.glassWarmAmber
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black87
                            : Colors.white.withValues(alpha: 0.75),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Frosted glass search bar pill ("🔍 Search ingredients").
class SproutGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onClear;

  const SproutGlassSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search ingredients',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (controller != null && controller!.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller?.clear();
                    onClear?.call();
                  },
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white60, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted modal bottom sheet wrapper matching the reference images.
class SproutGlassModalSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: SproutColors.glassSmokedDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: builder(ctx),
              ),
            ),
          ),
        );
      },
    );
  }
}
