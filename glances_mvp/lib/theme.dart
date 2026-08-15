import 'package:flutter/material.dart';

/// Design tokens taken from the Glances Figma and res/values/colors.xml.
///
/// Typography note: the Figma specifies Mukta, Khula and Inter — all free
/// Google Fonts. They are not bundled here to keep the build dependency-light.
/// To add them: drop the .ttf files in assets/fonts/, declare them in
/// pubspec.yaml, and set `fontFamily: 'Mukta'` in the ThemeData below.
class GlancesColors {
  static const primary = Color(0xFF3CBEEE);      // light_blue_400
  static const primaryLight = Color(0xFF63CBF2); // light_blue_300
  static const surfaceTint = Color(0xFF7DC6EE);  // light_blue_200
  static const accentLight = Color(0xFF96D1F1);  // blue_200
  static const accentDark = Color(0xFF13508B);   // blue_900
  static const orange = Color(0xFFF27C11);       // yellow_900
  static const textPrimary = Color(0xFF5D5D5D);  // grey_700
  static const textSecondary = Color(0xFF878787);// grey_650
  static const textTertiary = Color(0xFF707070); // grey_600
  static const border = Color(0xFFCECECE);       // grey_400
  static const divider = Color(0xFFE8E8E8);      // grey_200
  static const tutorialBubble = Color(0xFFB6DFF5);
  static const white = Colors.white;
}

class GlancesSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class GlancesRadius {
  static const button = 28.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

ThemeData glancesTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: GlancesColors.primary,
      primary: GlancesColors.primary,
      secondary: GlancesColors.orange,
    ),
    scaffoldBackgroundColor: GlancesColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: GlancesColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: GlancesColors.textPrimary,
      displayColor: GlancesColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlancesRadius.button),
        borderSide: const BorderSide(color: GlancesColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlancesRadius.button),
        borderSide: const BorderSide(color: GlancesColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlancesRadius.button),
        borderSide: const BorderSide(color: GlancesColors.primary, width: 2),
      ),
    ),
  );
}
