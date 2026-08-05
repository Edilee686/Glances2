import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GColors {
  static const orange = Color(0xFFF0800F);
  static const orangeDark = Color(0xFFD96C00);
  static const blue = Color(0xFF2CB0E8);
  static const blueDark = Color(0xFF1791C4);
  static const deep = Color(0xFF14324A);
  static const ink = Color(0xFF14171A);
  static const muted = Color(0xFF67717A);
  static const faint = Color(0xFF98A2AC);
  static const line = Color(0xFFE1E6EA);
  static const surface = Color(0xFFF6F9FB);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF23B26B);
  static const danger = Color(0xFFC0392B);
  static const tint = Color(0xFFEAF7FD);
}

class GText {
  static TextStyle display(Color c) =>
      GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: c, height: 1.15);
  static TextStyle title(Color c) =>
      GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c, height: 1.2);
  static TextStyle heading(Color c) =>
      GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.35, color: c);
  static TextStyle body(Color c) =>
      GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: c, height: 1.5);
  static TextStyle strong(Color c) =>
      GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: c);
  static TextStyle small(Color c) =>
      GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w500, color: c, height: 1.5);
  static TextStyle label(Color c) =>
      GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: c);
  static TextStyle mono(Color c, {double size = 11.5}) =>
      GoogleFonts.dmMono(fontSize: size, fontWeight: FontWeight.w400, color: c, letterSpacing: 0.6);
}

ThemeData glancesTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: GColors.surface,
    colorScheme: base.colorScheme.copyWith(
      primary: GColors.blue,
      secondary: GColors.orange,
      surface: GColors.white,
    ),
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    splashFactory: InkRipple.splashFactory,
  );
}

/// Minimum tap target used across the app (iOS HIG 44, Material 48).
const double kTapTarget = 48;
