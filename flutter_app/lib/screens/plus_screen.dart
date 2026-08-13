import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';
import '../widgets/heart.dart';

/// Frames 29/37-41/44: the Plus paywall and its five perks.
class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  static const _perks = [
    'Unlimited instant Likes',
    'Unlimited Pass both or Like both',
    'Send a Like with timer',
    'Undo Likes',
    'No ads',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.cyan,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              SizedBox(height: fx(context, 70)),
              TwoTonedHeart(size: fx(context, 230), solid: GColors.white),
              SizedBox(height: fx(context, 40)),
              Text('GLANCES PLUS',
                  style: GText.fig(context, 64, GColors.white, weight: FontWeight.w600)),
              SizedBox(height: fx(context, 16)),
              Text('Unlimited passes & like both',
                  style: GText.fig(context, 44, GColors.white.withValues(alpha: 0.9))),
              SizedBox(height: fx(context, 70)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: fx(context, 120)),
                  children: [
                    for (final perk in _perks)
                      Padding(
                        padding: EdgeInsets.only(bottom: fx(context, 44)),
                        child: Row(
                          children: [
                            Icon(Icons.check_rounded,
                                color: GColors.white, size: fx(context, 60)),
                            SizedBox(width: fx(context, 30)),
                            Expanded(
                              child: Text(perk, style: GText.fig(context, 44, GColors.white)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              FigButton(
                label: state.plus ? 'You have Plus' : 'Continue',
                background: GColors.white,
                foreground: GColors.cyan,
                onTap: state.plus
                    ? null
                    : () async {
                        await state.buyPlus();
                        if (!context.mounted) return;
                        Navigator.maybePop(context);
                      },
              ),
              SizedBox(height: fx(context, 24)),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(fx(context, 24)),
                  child: Text('No, thanks.', style: GText.fig(context, 44, GColors.white)),
                ),
              ),
              SizedBox(height: fx(context, 30)),
            ],
          ),
        ),
      ),
    );
  }
}
