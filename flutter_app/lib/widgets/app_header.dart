import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'buttons.dart';
import 'icons.dart';
import 'mode_switch.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.onDark, required this.unread});

  final bool onDark;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tint = onDark ? GColors.white : GColors.ink;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 8, 8),
      child: Row(
        children: [
          RoundIconButton(
            tooltip: 'Menu',
            onTap: () => Scaffold.of(context).openDrawer(),
            child: MenuGlyph(color: tint),
          ),
          Expanded(
            child: Center(
              child: ModeSwitch(
                mode: state.mode,
                onDark: onDark,
                onChanged: (m) {
                  state.setMode(m);
                  Navigator.pushReplacementNamed(context, m == SightMode.inSight ? Routes.sight : Routes.pick);
                },
              ),
            ),
          ),
          RoundIconButton(
            tooltip: 'Filters',
            onTap: () => Scaffold.of(context).openDrawer(),
            child: FunnelGlyph(color: tint),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              RoundIconButton(
                tooltip: 'Activity',
                onTap: () => Navigator.pushNamed(context, Routes.activity),
                child: EnvelopeGlyph(color: tint),
              ),
              if (unread > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(color: GColors.orange, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      unread.toString(),
                      style: GText.label(GColors.white).copyWith(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
