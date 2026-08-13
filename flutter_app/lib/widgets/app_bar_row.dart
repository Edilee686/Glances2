import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'fig.dart';

/// The core screen's top row: hamburger, the two-way toggle, and the envelope
/// with its orange unread badge (Figma: 40px badge, rgb(243,124,17)).
class GlancesTopRow extends StatelessWidget {
  const GlancesTopRow({super.key, required this.state, this.onDark = true});

  final AppState state;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final tint = onDark ? GColors.white : GColors.grey;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fx(context, 48), vertical: fx(context, 20)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.menu),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(fx(context, 20)),
              child: Icon(Icons.menu_rounded, color: tint, size: fx(context, 78)),
            ),
          ),
          const Spacer(),
          FigToggle(
            value: state.mode == SightMode.likesAndMessages,
            onChanged: (value) {
              state.setMode(value ? SightMode.likesAndMessages : SightMode.inSight);
              if (value) Navigator.pushNamed(context, Routes.activity);
            },
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.activity),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(fx(context, 12)),
              child: SizedBox(
                width: fx(context, 106),
                height: fx(context, 92),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(Icons.mail_rounded, color: tint, size: fx(context, 74)),
                    ),
                    if (state.unread > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: fx(context, 44),
                          height: fx(context, 44),
                          decoration: const BoxDecoration(
                            color: GColors.orange,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            state.unread > 9 ? '9+' : state.unread.toString(),
                            style: GText.fig(context, 28, GColors.white, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
