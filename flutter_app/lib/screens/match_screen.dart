import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';
import '../widgets/heart.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final person = state.active;
    return Scaffold(
      backgroundColor: GColors.cyan,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: fx(context, 620),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: fx(context, 40),
                    child: FigAvatar(
                      size: 420,
                      name: state.me?.name,
                      photoPath: state.me?.photoPath,
                      ringColor: GColors.white,
                      ringWidth: 16,
                      shadow: true,
                    ),
                  ),
                  Positioned(
                    right: fx(context, 40),
                    child: FigAvatar(
                      size: 420,
                      name: person?.name,
                      photoPath: person?.photoPath,
                      ringColor: GColors.white,
                      ringWidth: 16,
                      shadow: true,
                    ),
                  ),
                  Container(
                    width: fx(context, 220),
                    height: fx(context, 220),
                    decoration: BoxDecoration(
                      color: GColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: fx(context, 30),
                          offset: Offset(0, fx(context, 10)),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: TwoTonedHeart(size: fx(context, 120)),
                  ),
                ],
              ),
            ),
            SizedBox(height: fx(context, 80)),
            Text('It is a match!', style: GText.fig(context, 80, GColors.white)),
            SizedBox(height: fx(context, 30)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fx(context, 120)),
              child: Text(
                person == null
                    ? 'Say something before the moment passes.'
                    : person.name +
                        ' is still ' +
                        person.distanceM.toString() +
                        ' m away. Say something before the moment passes.',
                textAlign: TextAlign.center,
                style: GText.fig(context, 44, GColors.white, height: 1.35),
              ),
            ),
            const Spacer(),
            FigButton(
              label: 'Send a message',
              background: GColors.white,
              foreground: GColors.cyan,
              onTap: () => Navigator.pushReplacementNamed(context, Routes.chat),
            ),
            SizedBox(height: fx(context, 36)),
            GestureDetector(
              onTap: () => Navigator.popUntil(context, ModalRoute.withName(Routes.sight)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(fx(context, 24)),
                child: Text('Keep looking', style: GText.fig(context, 44, GColors.white)),
              ),
            ),
            SizedBox(height: fx(context, 40)),
          ],
        ),
      ),
    );
  }
}
