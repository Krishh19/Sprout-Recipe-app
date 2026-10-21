import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Central Sprout Material 3 theme configurations for Light and Dark modes.
class SproutTheme {
  SproutTheme._();

  /// Light Mode: Warm paper canvas, soft ivory card surfaces, deep botanical forest green brand
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: SproutColors.lightCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SproutColors.forestGreen,
        brightness: Brightness.light,
        primary: SproutColors.forestGreen,
        surface: SproutColors.lightSurface,
        onSurface: SproutColors.textPrimary,
        secondary: SproutColors.botanicalGreen,
        outline: SproutColors.subtleBorder,
      ),
      textTheme: GoogleFonts.karlaTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        iconTheme: IconThemeData(color: SproutColors.lightPrimaryInk),
      ),
      dividerColor: SproutColors.subtleBorder,
    );
  }

  /// Dark Mode: Deep botanical forest canvas, elevated dark green surface, vibrant mint accent
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SproutColors.nightCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SproutColors.nightAccent,
        brightness: Brightness.dark,
        primary: SproutColors.nightAccent,
        surface: SproutColors.nightSurface,
        onSurface: SproutColors.nightPrimaryInk,
        secondary: SproutColors.botanicalGreen,
        outline: Color(0xFF284031),
      ),
      textTheme: GoogleFonts.karlaTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        iconTheme: IconThemeData(color: SproutColors.nightPrimaryInk),
      ),
      iconTheme: const IconThemeData(
        color: SproutColors.nightPrimaryInk,
      ),
      dividerColor: const Color(0xFF284031),
    );
  }
}
