import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular photo with a striped placeholder while there is no image.
class PhotoCircle extends StatelessWidget {
  const PhotoCircle({
    super.key,
    required this.diameter,
    this.photoUrl,
    this.ringColor = GColors.white,
    this.ringWidth = 5,
    this.shadow = true,
    this.dim = 0,
  });

  final double diameter;
  final String? photoUrl;
  final Color ringColor;
  final double ringWidth;
  final bool shadow;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: shadow
            ? [BoxShadow(color: GColors.deep.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 14))]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl != null)
            Image.network(photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _StripePlaceholder())
          else
            const _StripePlaceholder(),
          if (dim > 0) ColoredBox(color: GColors.blue.withValues(alpha: dim)),
        ],
      ),
    );
  }
}

class _StripePlaceholder extends StatelessWidget {
  const _StripePlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(),
      child: Center(
        child: Text('photo', style: GText.mono(const Color(0xFFA3AEB8), size: 11)),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFCFD));
    final paint = Paint()
      ..color = const Color(0xFFEFF3F6)
      ..strokeWidth = 12;
    for (double x = -size.height; x < size.width + size.height; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
