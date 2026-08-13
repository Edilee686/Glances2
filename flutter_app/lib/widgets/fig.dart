import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The signature Glances sheet: a full-bleed panel whose bottom edge bows
/// downward. Figma path: M1080 1653.743 C 720 1888.752, 360 1888.752, 0 1653.743
/// on a 1080x1830 box - the curve drops 235.009 units below the straight edge.
class CurvedSheetClipper extends CustomClipper<Path> {
  const CurvedSheetClipper({this.bulge = 0.128});

  /// Curve depth as a fraction of width (235.009 / 1830 height ~ 0.2176 of the
  /// sheet, expressed against width for stable proportions).
  final double bulge;

  @override
  Path getClip(Size size) {
    final drop = size.width * bulge;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - drop)
      ..cubicTo(
        size.width * 0.667, size.height,
        size.width * 0.333, size.height,
        0, size.height - drop,
      )
      ..close();
  }

  @override
  bool shouldReclip(CurvedSheetClipper oldClipper) => oldClipper.bulge != bulge;
}

class CurvedSheet extends StatelessWidget {
  const CurvedSheet({
    super.key,
    this.child,
    this.color = GColors.white,
    this.bulge = 0.128,
  });

  /// Optional - the sheet is usually just a coloured backdrop.
  final Widget? child;
  final Color color;
  final double bulge;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CurvedSheetClipper(bulge: bulge),
      child: SizedBox.expand(child: ColoredBox(color: color, child: child)),
    );
  }
}

/// 880x120 pill, radius 60, drop shadow 4/8/16 - the only button in the design.
class FigButton extends StatelessWidget {
  const FigButton({
    super.key,
    required this.label,
    this.onTap,
    this.background = GColors.cyan,
    this.foreground = GColors.white,
    this.fontSize = 46,
    this.leading,
    this.width = 880,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final double fontSize;
  final Widget? leading;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final on = enabled && onTap != null;
    return Opacity(
      opacity: on ? 1 : 0.45,
      child: GestureDetector(
        onTap: on ? onTap : null,
        child: Container(
          width: fx(context, width),
          height: fx(context, 120),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(fx(context, 60)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: Offset(fx(context, 4), fx(context, 8)),
                blurRadius: fx(context, 16),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: fx(context, 24)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.fig(context, fontSize, foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The empty-photo circle: a translucent white ring around a flat grey disc.
/// Figma: 610 outer rgba(255,255,255,0.25), 556 inner rgb(238,238,238).
class FigAvatar extends StatelessWidget {
  const FigAvatar({
    super.key,
    required this.size,
    this.photoPath,
    this.name,
    this.ringColor = const Color(0x40FFFFFF),
    this.ringWidth = 27,
    this.shadow = false,
    this.dim = 0,
  });

  final double size;
  final String? photoPath;
  final String? name;
  final Color ringColor;
  final double ringWidth;
  final bool shadow;
  final double dim;

  @override
  Widget build(BuildContext context) {
    final d = fx(context, size);
    final ring = fx(context, ringWidth);
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: Offset(fx(context, 8), fx(context, 8)),
                  blurRadius: fx(context, 24),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(ring),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _fill(context, d - ring * 2),
            if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
          ],
        ),
      ),
    );
  }

  Widget _fill(BuildContext context, double inner) {
    final path = photoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    final label = (name ?? '').trim();
    if (label.isEmpty) return const ColoredBox(color: GColors.circle);
    return Container(
      color: GColors.circle,
      alignment: Alignment.center,
      child: Text(
        label.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: inner * 0.36,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFBFBFBF),
        ),
      ),
    );
  }
}

/// The two-state switch on the core screen. Figma: 200x70 white pill with an
/// inset shadow, 106x54 knob in rgb(125,198,238).
class FigToggle extends StatelessWidget {
  const FigToggle({super.key, required this.value, required this.onChanged});

  /// false = left (in sight), true = right (likes and messages).
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: fx(context, 200),
        height: fx(context, 70),
        decoration: BoxDecoration(
          color: GColors.white,
          borderRadius: BorderRadius.circular(fx(context, 35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: fx(context, 8),
              offset: Offset(0, fx(context, 2)),
            ),
          ],
        ),
        padding: EdgeInsets.all(fx(context, 8)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: fx(context, 106),
            height: fx(context, 54),
            decoration: BoxDecoration(
              color: GColors.skyLight,
              borderRadius: BorderRadius.circular(fx(context, 35)),
            ),
            alignment: Alignment.center,
            child: Icon(
              value ? Icons.mail_outline_rounded : Icons.remove_red_eye_outlined,
              color: GColors.white,
              size: fx(context, 34),
            ),
          ),
        ),
      ),
    );
  }
}

/// The GLANCES wordmark strip that sits at the top of most frames
/// (Figma: left 30, top 30, 1019.44 x 29.2).
class FigWordmark extends StatelessWidget {
  const FigWordmark({super.key, this.color = GColors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'G L A N C E S',
      style: GText.fig(context, 34, color, weight: FontWeight.w600).copyWith(
        letterSpacing: fx(context, 10),
      ),
    );
  }
}

/// Chevron used for back and carousel arrows (Figma 20x38 with a soft shadow).
class FigChevron extends StatelessWidget {
  const FigChevron({
    super.key,
    this.left = true,
    this.color = GColors.white,
    this.size = 38,
    this.onTap,
  });

  final bool left;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(fx(context, 22)),
        child: Icon(
          left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          color: color,
          size: fx(context, size * 1.6),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: fx(context, 8),
              offset: Offset(fx(context, 2), fx(context, 2)),
            ),
          ],
        ),
      ),
    );
  }
}
