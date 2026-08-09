import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final person = state.activePerson;
    return Scaffold(
      backgroundColor: GColors.blue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: 176,
                          height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Image.asset('assets/images/mark.png', width: 96),
                        ),
                        const SizedBox(height: 22),
                        Text('MUTUAL GLANCE',
                            style: GText.mono(Colors.white.withValues(alpha: 0.85), size: 11)
                                .copyWith(letterSpacing: 2.4)),
                        const SizedBox(height: 14),
                        Text('You both looked.', style: GText.display(GColors.white).copyWith(fontSize: 32)),
                        const SizedBox(height: 14),
                        Text(
                          person == null
                              ? 'Say something before the moment passes.'
                              : person.name + ' is still ' + person.distanceLabel +
                                  ' away. Say something before the moment passes.',
                          textAlign: TextAlign.center,
                          style: GText.body(Colors.white.withValues(alpha: 0.92)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PillButton(
                label: 'Send a message',
                background: GColors.white,
                foreground: GColors.ink,
                onPressed: () => Navigator.pushReplacementNamed(context, Routes.chat),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Keep looking',
                background: Colors.white.withValues(alpha: 0.18),
                border: Colors.white.withValues(alpha: 0.45),
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName(Routes.sight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
