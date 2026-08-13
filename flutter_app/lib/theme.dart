import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every number in this app is transcribed from the 1080x1920 Figma frames.
/// [fx] converts a Figma pixel into a logical pixel on the current screen, so
/// the layout stays proportionally identical on any handset.
const double kFigmaWidth = 1080;
const double kFigmaHeight = 1920;

double fx(BuildContext context, double figmaPx) =>
    figmaPx * MediaQuery.sizeOf(context).width / kFigmaWidth;

extension FigNum on num {
  double x(BuildContext context) => fx(context, toDouble());
}

class GColors {
  static const cyan = Color(0xFF3CBEEE); // rgb(60,190,238) panels + primary
  static const blue = Color(0xFF25A7DF); // rgb(37,167,223) logo blue
  static const skyLight = Color(0xFF7DC6EE); // rgb(125,198,238)
  static const orange = Color(0xFFF37C11); // rgb(243,124,17)
  static const facebook = Color(0xFF13508B); // rgb(19,80,139)
  static const grey = Color(0xFF5D5D5D); // rgb(93,93,93) body text
  static const greyMid = Color(0xFF777777);
  static const greyLine = Color(0xFFAEAEAE); // rgb(174,174,174)
  static const greyDim = Color(0xFFCDCDCD); // rgb(205,205,205)
  static const greyFaint = Color(0xFFE0E0E0); // rgb(224,224,224) placeholder
  static const circle = Color(0xFFEEEEEE); // rgb(238,238,238) empty photo
  static const white = Color(0xFFFFFFFF);
  static const scrim = Color(0xFF202020);
  static const gradientBottom = Color(0xFFABD6EF); // splash gradient end
}

/// Mukta at Figma sizes. Pass the Figma font size; it is scaled for you.
class GText {
  static TextStyle fig(BuildContext context, double figmaSize, Color color,
          {FontWeight weight = FontWeight.w400, double height = 1.15}) =>
      GoogleFonts.mukta(
        fontSize: fx(context, figmaSize),
        fontWeight: weight,
        color: color,
        height: height,
      );
}

ThemeData glancesTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: GColors.white,
    colorScheme: base.colorScheme.copyWith(
      primary: GColors.cyan,
      secondary: GColors.orange,
      surface: GColors.white,
    ),
    textTheme: GoogleFonts.muktaTextTheme(base.textTheme),
    splashFactory: InkRipple.splashFactory,
  );
}
