import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/tutorial/tutorial_steps.dart';
import '../colors.dart';
import '../motion.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';
import 'sprout_bouncy_tap.dart';

/// Floating glass pill navigation with a detached, never-clipped
/// scan button hovering above it.
///
/// Pair with `Scaffold(extendBody: true)` in the parent.
class SproutGlassNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onScanTap;

  const SproutGlassNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final isScanActive = currentIndex == 2;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final pillBottom = bottomInset > 0 ? bottomInset + 4 : 12.0;

    return SizedBox(
      // 64px pill + overflow room for the detached scan button
      height: 90 + pillBottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Floating glass pill — blur is clipped to the pill's own
          // continuous squircle shape, so it can never clip the scan button.
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, pillBottom),
            child: ClipPath(
              clipper: SproutRadii.clipperNav(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: 64,
                  decoration: ShapeDecoration(
                    color: (isDark ? SproutColors.nightSurface : SproutColors.lightSurface)
                        .withValues(alpha: 0.86),
                    shape: SproutRadii.squircleNav(
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : SproutColors.sage.withValues(alpha: 0.28),
                        width: 1.0,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        label: 'Home',
                        icon: Icons.cottage_outlined,
                        activeIcon: Icons.cottage_rounded,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 1,
                        label: 'Explore',
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        isDark: isDark,
                      ),
                      // Space for the detached center scan button
                      const SizedBox(width: 64),
                      SproutShowcase(
                        step: MainTourSteps.saved,
                        child: _buildNavItem(
                          index: 3,
                          label: 'Saved',
                          icon: Icons.bookmark_border_rounded,
                          activeIcon: Icons.bookmark_rounded,
                          isDark: isDark,
                        ),
                      ),
                      SproutShowcase(
                        step: MainTourSteps.profile,
                        child: _buildNavItem(
                          index: 4,
                          label: 'Profile',
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Detached scan button — floats above the pill, never clipped.
          Positioned(
            bottom: pillBottom + 20,
            child: Semantics(
              button: true,
              selected: isScanActive,
              label: 'Scan ingredients',
              child: SproutBouncyTap(
                scaleFactor: 0.92,
                onTap: () {
                  SproutHaptics.medium();
                  onScanTap();
                },
                child: AnimatedScale(

                  scale: isScanActive ? 1.08 : 1.0,
                  duration: SproutMotion.medium,
                  curve: SproutMotion.bounce,
                  child: AnimatedContainer(
                    duration: SproutMotion.medium,
                    curve: SproutMotion.emphasized,
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          SproutColors.sproutGreen,
                          SproutColors.leaf,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isScanActive
                            ? SproutColors.butter.withValues(alpha: 0.9)
                            : (isDark ? SproutColors.nightSurface : SproutColors.lightSurface),
                        width: isScanActive ? 3.0 : 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? SproutColors.nightAccent : SproutColors.sproutGreen).withValues(
                            alpha: isScanActive ? 0.5 : 0.35,
                          ),
                          blurRadius: isScanActive ? 20 : 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    // Active tab uses pure color highlight: vivid mint in dark mode, deep sprout green in light mode
    final highlightColor = isDark ? SproutColors.nightAccent : SproutColors.sproutGreen;
    final unselectedColor = isDark ? SproutColors.nightSecondaryInk : SproutColors.lightSecondaryInk;

    final iconColor = isSelected ? highlightColor : unselectedColor;
    final textColor = isSelected ? highlightColor : unselectedColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      child: SproutBouncyTap(
        scaleFactor: 0.95,
        onTap: () {
          SproutHaptics.selection();
          onIndexChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          // No enclosing box pill: active tab is expressed solely through color and icon highlight
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          constraints: const BoxConstraints(minWidth: 54, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon swap with scale bounce
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey<bool>(isSelected),
                  color: iconColor,
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: SproutTypography.caption(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 2),
              // Selection indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected && isDark
                      ? [
                          BoxShadow(
                            color: highlightColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

