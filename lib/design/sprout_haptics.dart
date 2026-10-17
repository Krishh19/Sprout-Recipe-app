import 'package:flutter/services.dart';

/// Centralized tactile haptic system for Sprout.
///
/// Provides intentional sensory profiles across user interactions
/// to make the interface feel physical, crisp, and responsive.
class SproutHaptics {
  SproutHaptics._();

  /// Subtle click for chips, segment switches, and tab changes.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light tactile pop for bouncy card taps and primary buttons.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium tactile pulse for scanner ingredient identification or toggle actions.
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy tactile thud for meal completion, timer alerts, or major achievements.
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Multi-pulse celebratory haptic burst for major milestones (e.g. cooking finished).
  static void success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.lightImpact();
  }
}
