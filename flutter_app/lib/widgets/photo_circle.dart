import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular photo. With no image it falls back to a coloured monogram so people
/// still read as distinct individuals.
class PhotoCircle extends StatelessWidget {
  const PhotoCircle({
    super.key,
    required this.diameter,
    this.photoUrl,
    this.name,
    this.ringColor = GColors.white,
    this.ringWidth = 5,
    this.shadow = true,
    this.dim = 0,
  });

  final double diameter;
  final String? photoUrl;
  final String? name;
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
            Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Monogram(name: name, diameter: diameter),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _Monogram(name: name, diameter: diameter),
            )
          else
            _Monogram(name: name, diameter: diameter),
          if (dim > 0) ColoredBox(color: GColors.blue.withValues(alpha: dim)),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name, required this.diameter});

  final String? name;
  final double diameter;

  static const _palette = [
    [Color(0xFFFFD9B0), Color(0xFFF0800F)],
    [Color(0xFFCFE9FA), Color(0xFF1FA0E0)],
    [Color(0xFFDCE4EC), Color(0xFF5A6B7B)],
    [Color(0xFFFFE1DA), Color(0xFFE1614A)],
    [Color(0xFFD9EEE2), Color(0xFF2F9E6B)],
  ];

  @override
  Widget build(BuildContext context) {
    final label = (name ?? '').trim();
    final pair = _palette[label.isEmpty ? 2 : label.hashCode.abs() % _palette.length];
    return Container(
      color: pair[0],
      alignment: Alignment.center,
      child: label.isEmpty
          ? Icon(Icons.person_rounded, color: pair[1], size: diameter * 0.42)
          : Text(
              label.substring(0, 1).toUpperCase(),
              style: GText.display(pair[1]).copyWith(fontSize: diameter * 0.4, height: 1),
            ),
    );
  }
}
