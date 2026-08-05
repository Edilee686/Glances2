import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

/// Labelled two-way switch between the core sight view and the pick round.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({super.key, required this.mode, required this.onChanged, required this.onDark});

  final SightMode mode;
  final ValueChanged<SightMode> onChanged;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFE7EDF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('In sight', SightMode.inSight),
          const SizedBox(width: 2),
          _segment('Pick one', SightMode.pickOne),
        ],
      ),
    );
  }

  Widget _segment(String label, SightMode value) {
    final selected = mode == value;
    final Color bg = selected ? (onDark ? GColors.white : GColors.blue) : Colors.transparent;
    final Color fg = selected
        ? (onDark ? GColors.deep : GColors.white)
        : (onDark ? GColors.white : GColors.muted);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            style: GText.label(fg).copyWith(fontSize: 11.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
