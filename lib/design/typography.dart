import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class SproutTypography {
  // Display / Serif (Fraunces)
  static TextStyle display({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 38,
        height: 42 / 38,
        fontWeight: FontWeight.w700,
        color: color ?? SproutColors.primaryInk,
        letterSpacing: -0.5,
      );

  static TextStyle h1({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 30,
        height: 36 / 30,
        fontWeight: FontWeight.w700,
        color: color ?? SproutColors.primaryInk,
        letterSpacing: -0.3,
      );

  static TextStyle h2({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w600,
        color: color ?? SproutColors.primaryInk,
      );

  static TextStyle h3({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: color ?? SproutColors.primaryInk,
      );

  // Golden Metallic Heading styles
  static TextStyle metallicDisplay({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize ?? 38,
        height: 42 / 38,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
        color: SproutColors.isDarkMode
            ? SproutColors.metallicGoldBase
            : SproutColors.primaryInk,
      );

  static TextStyle metallicH1({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize ?? 30,
        height: 36 / 30,
        fontWeight: fontWeight,
        letterSpacing: -0.3,
        color: SproutColors.isDarkMode
            ? SproutColors.metallicGoldBase
            : SproutColors.primaryInk,
      );

  static TextStyle metallicH2({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize ?? 24,
        height: 30 / 24,
        fontWeight: fontWeight,
        color: SproutColors.isDarkMode
            ? SproutColors.metallicGoldBase
            : SproutColors.primaryInk,
      );

  // Body / UI (Karla)
  static TextStyle body({
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.karla(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: fontWeight,
        color: color ?? SproutColors.primaryInk,
      );

  static TextStyle bodyBold({Color? color}) =>
      GoogleFonts.karla(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
        color: color ?? SproutColors.primaryInk,
      );

  static TextStyle small({
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.karla(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: fontWeight,
        color: color ?? SproutColors.secondaryInk,
      );

  static TextStyle smallBold({Color? color}) =>
      GoogleFonts.karla(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: color ?? SproutColors.primaryInk,
      );

  static TextStyle caption({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) =>
      GoogleFonts.karla(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: fontWeight,
        color: color ?? SproutColors.muted,
      );

  // Handwritten / Display Accent (Kalam)
  static TextStyle handwritten({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.kalam(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? SproutColors.primaryInk,
        height: height,
        letterSpacing: letterSpacing,
      );
}
