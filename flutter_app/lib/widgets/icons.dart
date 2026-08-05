import 'package:flutter/material.dart';

/// Hamburger and funnel drawn as shapes so they never collide visually.
class MenuGlyph extends StatelessWidget {
  const MenuGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [bar(), const SizedBox(height: 4), bar(), const SizedBox(height: 4), bar()],
    );
  }
}

class FunnelGlyph extends StatelessWidget {
  const FunnelGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 18), painter: _FunnelPainter(color));
  }
}

class _FunnelPainter extends CustomPainter {
  _FunnelPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 1)
      ..lineTo(size.width, 1)
      ..lineTo(size.width / 2 + 2.5, size.height * 0.55)
      ..lineTo(size.width / 2 + 2.5, size.height)
      ..lineTo(size.width / 2 - 2.5, size.height - 3)
      ..lineTo(size.width / 2 - 2.5, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FunnelPainter oldDelegate) => oldDelegate.color != color;
}

class EnvelopeGlyph extends StatelessWidget {
  const EnvelopeGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.mail_outline_rounded, size: 24, color: color);
  }
}
