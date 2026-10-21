import 'package:flutter/material.dart';

/// Central botanical colour system for Sprout.
///
/// Combines a warm, paper-like editorial aesthetic with fresh botanical greens,
/// earthy terracottas, and accessible contrast in both light and dark modes.
class SproutColors {
  // Theme state
  static bool isDarkMode = false;

  static void setDarkMode(bool dark) {
    isDarkMode = dark;
  }

  /// Utility to resolve color depending on active theme mode
  static Color resolve(Color light, Color dark) => isDarkMode ? dark : light;

  // ---------------------------------------------------------------------------
  // Canonical Brand Palette (Prompt Specification)
  // ---------------------------------------------------------------------------
  static const Color warmPaper = Color(0xFFF6F3EA);
  static const Color softIvory = Color(0xFFFFFCF5);
  static const Color forestGreen = Color(0xFF203F2D);
  static const Color botanicalGreen = Color(0xFF557C4F);
  static const Color sage = Color(0xFFA7B79C);
  static const Color paleSage = Color(0xFFE5EBDD);
  static const Color terracotta = Color(0xFFAC6243);
  static const Color carrot = Color(0xFFD98A45);
  static const Color butter = Color(0xFFE9C56A);
  static const Color mutedBlue = Color(0xFF668DA8);
  static const Color textPrimary = Color(0xFF24352A);
  static const Color textSecondary = Color(0xFF647064);
  static const Color subtleBorder = Color(0xFFE4E0D5);

  // ---------------------------------------------------------------------------
  // Base Neutrals & Surfaces (Light Mode)
  // ---------------------------------------------------------------------------
  static const Color lightCanvas = Color(0xFFF0F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevatedSurface = Color(0xFFFFFFFF);
  static const Color lightPrimaryInk = Color(0xFF13362B);
  static const Color lightSecondaryInk = textSecondary;
  static const Color lightMuted = Color(0xFF889688);

  // Background Gradient tokens (Light Mode: Warm paper with subtle natural lighting)
  static const Color lightSkyTop = sage;
  static const Color lightSkyMid = Color(0xFFF3EEE3);
  static const Color lightSkySoft = Color(0xFFF6F3EA);
  static const Color lightSkyBase = Color(0xFFF9F7F1);

  static const LinearGradient lightSkyBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.30, 0.70, 1.0],
    colors: [
      lightSkyTop,
      lightSkyMid,
      lightSkySoft,
      lightSkyBase,
    ],
  );

  static const LinearGradient paperBackgroundGradient = lightSkyBackgroundGradient;

  // Brand greens
  static const Color sproutGreen = Color(0xFF214B38);
  static const Color leaf = botanicalGreen;

  // Warm food accents
  static const Color tomato = Color(0xFFBA543C);
  static const Color peach = Color(0xFFE8C8B5);

  // Gold / Warm Ochre Gradient tokens (for luxury warm botanical accents)
  static const Color metallicGoldLight = Color(0xFFFFEEBA);
  static const Color metallicGoldBase = Color(0xFFE9C56A);
  static const Color metallicGoldDeep = Color(0xFFD98A45);
  static const Color metallicGoldSheen = Color(0xFFFDE89C);
  static const Color metallicGoldBronze = Color(0xFFB57732);

  static const List<Color> metallicGoldGradientColors = [
    metallicGoldLight,
    metallicGoldBase,
    metallicGoldDeep,
    metallicGoldSheen,
    metallicGoldBronze,
  ];

  static const List<double> metallicGoldGradientStops = [0.0, 0.25, 0.55, 0.8, 1.0];

  static LinearGradient get goldGradient => const LinearGradient(
    colors: metallicGoldGradientColors,
    stops: metallicGoldGradientStops,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic
  static const Color success = Color(0xFF4C7B53);
  static const Color warning = carrot;
  static const Color error = Color(0xFFB84A3B);

  // Glass tokens (light mode: frosted ivory glass with subtle border)
  static const Color lightGlassBackground = Color(0xD9FFFCF5);
  static const Color lightGlassBorder = Color(0x66E4E0D5);

  // ---------------------------------------------------------------------------
  // Night & Deep Forest tokens (Dark Mode counterpart)
  // ---------------------------------------------------------------------------
  static const Color nightCanvas = Color(0xFF080E12);
  static const Color nightSurface = Color(0xFF121E23);
  static const Color nightElevatedSurface = Color(0xFF1A2B32);
  static const Color nightPrimaryInk = Color(0xFFF0FDF8);
  static const Color nightSecondaryInk = Color(0xFF9CB1A1);
  static const Color nightMuted = Color(0xFF6B8071);
  static const Color nightAccent = Color(0xFF4ADE80);
  static const Color nightGlassBackground = Color(0xCC182B20);
  static const Color nightGlassBorder = Color(0x3355C47A);

  // Atmospheric Forest Background Gradient tokens (Dark Mode)
  static const Color nightSkyTop = Color(0xFF1E3528);
  static const Color nightSkyMid = Color(0xFF182B20);
  static const Color nightSkySoft = Color(0xFF14241B);
  static const Color nightSkyBase = Color(0xFF111E16);

  static const LinearGradient nightSkyBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.25, 0.65, 1.0],
    colors: [
      nightSkyTop,
      nightSkyMid,
      nightSkySoft,
      nightSkyBase,
    ],
  );

  // ---------------------------------------------------------------------------
  // Dynamic tokens matching active theme
  // ---------------------------------------------------------------------------
  static Color get canvas => isDarkMode ? nightCanvas : lightCanvas;
  static Color get surface => isDarkMode ? nightSurface : lightSurface;
  static Color get elevatedSurface => isDarkMode ? nightElevatedSurface : lightElevatedSurface;
  static Color get primaryInk => isDarkMode ? nightPrimaryInk : lightPrimaryInk;
  static Color get secondaryInk => isDarkMode ? nightSecondaryInk : lightSecondaryInk;
  static Color get muted => isDarkMode ? nightMuted : lightMuted;
  static Color get border => isDarkMode ? Color(0xFF284031) : subtleBorder;
  static Color get glassBackground => isDarkMode ? nightGlassBackground : lightGlassBackground;
  static Color get glassBorder => isDarkMode ? nightGlassBorder : lightGlassBorder;
  static Color get accent => isDarkMode ? nightAccent : sproutGreen;

  // Active theme background gradient
  static LinearGradient get backgroundGradient =>
      isDarkMode ? nightSkyBackgroundGradient : lightSkyBackgroundGradient;
}
