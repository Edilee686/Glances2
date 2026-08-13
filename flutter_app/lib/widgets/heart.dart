import 'package:flutter/material.dart';

import '../theme.dart';

/// The Glances mark - a heart split into a blue left lobe and an orange right
/// lobe, as in the Figma splash (Vector 106x169 orange, 102x171 blue).
class TwoTonedHeart extends StatelessWidget {
  const TwoTonedHeart({super.key, required this.size, this.solid});

  final double size;

  /// When set, draws the whole heart in one colour (used on buttons and pills).
  final Color? solid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.96,
      child: CustomPaint(painter: _HeartPainter(solid: solid)),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({this.solid});

  final Color? solid;

  @override
  void paint(Canvas canvas, Size size) {
    // Figma path (50x48 viewBox) scaled to the requested size.
    final k = size.width / 50;
    final path = Path()
      ..moveTo(13.516 * k, 0)
      ..cubicTo(19.18 * k, 0, 21.896 * k, 2.466 * k, 25 * k, 6.195 * k)
      ..cubicTo(28.113 * k, 2.457 * k, 30.828 * k, 0, 36.484 * k, 0)
      ..cubicTo(37.193 * k, 0, 37.945 * k, 0.044 * k, 38.75 * k, 0.113 * k)
      ..cubicTo(43.653 * k, 0.592 * k, 49.308 * k, 5.115 * k, 50 * k, 13.775 * k)
      ..lineTo(50 * k, 16.659 * k)
      ..cubicTo(49.36 * k, 24.945 * k, 43.143 * k, 35.174 * k, 25 * k, 48 * k)
      ..cubicTo(6.849 * k, 35.174 * k, 0.64 * k, 24.945 * k, 0, 16.659 * k)
      ..lineTo(0, 13.775 * k)
      ..cubicTo(0.692 * k, 5.115 * k, 6.356 * k, 0.592 * k, 11.259 * k, 0.113 * k)
      ..cubicTo(12.063 * k, 0.035 * k, 12.807 * k, 0, 13.516 * k, 0)
      ..close();

    final single = solid;
    if (single != null) {
      canvas.drawPath(path, Paint()..color = single);
      return;
    }

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      Paint()..color = GColors.blue,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = GColors.orange,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) => oldDelegate.solid != solid;
}
