import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/colors.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String keyThemeMode = 'sprout_theme_mode';
  bool _userExplicitlySet = false;

  @override
  ThemeMode build() {
    // Attempt async preference load in microtask
    Future.microtask(() => _hydrateFromPrefs());
    return ThemeMode.system;
  }

  Future<void> _hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userExplicitlySet) return;
      final saved = prefs.getString(keyThemeMode);
      if (_userExplicitlySet) return;
      if (saved == 'dark') {
        state = ThemeMode.dark;
        SproutColors.setDarkMode(true);
      } else if (saved == 'light') {
        state = ThemeMode.light;
        SproutColors.setDarkMode(false);
      } else if (saved == 'system') {
        state = ThemeMode.system;
        final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        SproutColors.setDarkMode(platformDark);
      }
    } catch (_) {
      // Fallback to system default if SharedPreferences is unavailable in test environment
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userExplicitlySet = true;
    state = mode;
    if (mode == ThemeMode.dark) {
      SproutColors.setDarkMode(true);
    } else if (mode == ThemeMode.light) {
      SproutColors.setDarkMode(false);
    } else {
      final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      SproutColors.setDarkMode(platformDark);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system';
      await prefs.setString(keyThemeMode, value);
    } catch (_) {}
  }

  Future<void> toggleDarkMode() async {
    final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final isCurrentlyDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && platformDark);
    await setThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
