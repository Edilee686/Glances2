import 'package:flutter/material.dart';

import '../theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = GColors.blue,
    this.foreground = GColors.white,
    this.border,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        shape: StadiumBorder(side: border == null ? BorderSide.none : BorderSide(color: border!, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 10)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GText.strong(foreground).copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDark = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? (selected ? GColors.white : Colors.white.withValues(alpha: 0.22))
        : (selected ? GColors.blue : GColors.white);
    final fg = onDark ? (selected ? GColors.ink : GColors.white) : (selected ? GColors.white : GColors.muted);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: onDark || selected ? BorderSide.none : const BorderSide(color: GColors.line, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(label, style: GText.strong(fg)),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = kTapTarget,
    this.background = Colors.transparent,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final double size;
  final Color background;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
