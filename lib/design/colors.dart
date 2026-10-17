import 'package:flutter/material.dart';

class SproutColors {
  // Theme state
  static bool isDarkMode = false;

  static void setDarkMode(bool dark) {
    isDarkMode = dark;
  }

  /// Utility to resolve color depending on active theme mode
  static Color resolve(Color light, Color dark) => isDarkMode ? dark : light;

  // Base neutrals (light)
  static const Color lightCanvas = Color(0xFFF6F0E3);
  static const Color lightSurface = Color(0xFFFBF7EE);
  static const Color lightElevatedSurface = Color(0xFFFFFDF7);
  static const Color lightPrimaryInk = Color(0xFF18372B);
  static const Color lightSecondaryInk = Color(0xFF637067);
  static const Color lightMuted = Color(0xFFA4A69B);

  // Brand greens
  static const Color sproutGreen = Color(0xFF214B38);
  static const Color leaf = Color(0xFF3F6B45);
  static const Color sage = Color(0xFF8FA486);

  // Warm accents
  static const Color carrot = Color(0xFFF28B45);
  static const Color tomato = Color(0xFFE95D45);
  static const Color butter = Color(0xFFF2C96D);
  static const Color peach = Color(0xFFEFB89D);

  // Metallic Gold Gradient tokens (for luxury metallic main headings)
  static const Color metallicGoldLight = Color(0xFFFFEEBA); // Pale radiant champagne highlight
  static const Color metallicGoldBase = Color(0xFFF7CF76);  // Lustrous warm gold
  static const Color metallicGoldDeep = Color(0xFFE2A63B);  // Polished rich amber
  static const Color metallicGoldSheen = Color(0xFFFDE89C); // Shimmer specular reflection
  static const Color metallicGoldBronze = Color(0xFFC4861C);// Deep bronze metallic base

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
  static const Color success = Color(0xFF527A53);
  static const Color warning = Color(0xFFD79A42);
  static const Color error = Color(0xFFC95B4B);

  // Glass tokens (light mode: white @ 65% / 55% alpha)
  static const Color lightGlassBackground = Color(0xA6FFFFFF);
  static const Color lightGlassBorder = Color(0x8CFFFFFF);

  // Night & Low-Light Kitchen tokens
  static const Color nightCanvas = Color(0xFF111814);
  static const Color nightSurface = Color(0xFF1A241F);
  static const Color nightElevatedSurface = Color(0xFF223029);
  static const Color nightPrimaryInk = Color(0xFFF0FDF4);
  static const Color nightSecondaryInk = Color(0xFFA7B3A9);
  static const Color nightMuted = Color(0xFF5F6E64);
  static const Color nightAccent = Color(0xFF4ADE80);
  static const Color nightGlassBackground = Color(0xCC1A241F);
  static const Color nightGlassBorder = Color(0x334ADE80);

  // Dynamic tokens matching active theme
  static Color get canvas => isDarkMode ? nightCanvas : lightCanvas;
  static Color get surface => isDarkMode ? nightSurface : lightSurface;
  static Color get elevatedSurface => isDarkMode ? nightElevatedSurface : lightElevatedSurface;
  static Color get primaryInk => isDarkMode ? nightPrimaryInk : lightPrimaryInk;
  static Color get secondaryInk => isDarkMode ? nightSecondaryInk : lightSecondaryInk;
  static Color get muted => isDarkMode ? nightMuted : lightMuted;
  static Color get glassBackground => isDarkMode ? nightGlassBackground : lightGlassBackground;
  static Color get glassBorder => isDarkMode ? nightGlassBorder : lightGlassBorder;
  static Color get accent => isDarkMode ? nightAccent : sproutGreen;
}
