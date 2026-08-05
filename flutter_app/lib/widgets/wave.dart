import 'package:flutter/material.dart';

/// The curved band used across onboarding and the sight screen.
class WaveClipper extends CustomClipper<Path> {
  WaveClipper({this.fromTop = false, this.depth = 44});

  final bool fromTop;
  final double depth;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (fromTop) {
      path.moveTo(0, depth);
      path.quadraticBezierTo(size.width / 2, -depth, size.width, depth);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.lineTo(0, size.height - depth);
      path.quadraticBezierTo(size.width / 2, size.height + depth, size.width, size.height - depth);
      path.lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => oldClipper.fromTop != fromTop || oldClipper.depth != depth;
}

class WavePanel extends StatelessWidget {
  const WavePanel({
    super.key,
    required this.child,
    this.color,
    this.fromTop = true,
    this.padding = const EdgeInsets.fromLTRB(28, 46, 28, 40),
  });

  final Widget child;
  final Color? color;
  final bool fromTop;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(fromTop: fromTop),
      child: Container(
        width: double.infinity,
        color: color ?? Colors.white,
        padding: padding,
        child: child,
      ),
    );
  }
}
