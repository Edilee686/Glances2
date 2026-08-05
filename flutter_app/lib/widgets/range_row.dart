import 'package:flutter/material.dart';

import '../theme.dart';

/// Slider row whose end labels can never be occluded by the thumb:
/// labels do not shrink, and the track keeps clearance on both sides.
class RangeRow extends StatelessWidget {
  const RangeRow({
    super.key,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.caption,
  });

  final String minLabel;
  final String maxLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(minLabel, style: GText.label(GColors.muted), maxLines: 1),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: GColors.blue,
                  inactiveTrackColor: GColors.line,
                  thumbColor: GColors.white,
                  overlayColor: GColors.blue.withValues(alpha: 0.12),
                  thumbShape: const _RingThumb(),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(value: value, min: min, max: max, onChanged: onChanged),
              ),
            ),
            const SizedBox(width: 12),
            Text(maxLabel, style: GText.label(GColors.muted), maxLines: 1),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(caption!, style: GText.mono(GColors.faint, size: 11), maxLines: 1),
        ],
      ],
    );
  }
}

class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 11, Paint()..color = GColors.white);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = GColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
