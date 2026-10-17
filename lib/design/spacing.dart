import 'package:flutter/material.dart';

class SproutSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // Standard screen margins
  static const double screenPadding = 20.0;
  static const EdgeInsets screenInsets = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets screenInsetsWithTop = EdgeInsets.fromLTRB(screenPadding, s16, screenPadding, 0);

  // Standard bottom inset for scrollable content over the floating glass nav bar
  static const double navClearance = 124.0;
}
