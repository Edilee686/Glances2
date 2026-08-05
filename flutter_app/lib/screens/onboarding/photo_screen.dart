import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/wave.dart';

class PhotoScreen extends StatelessWidget {
  const PhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.blue,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 8, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RoundIconButton(
                tooltip: 'Back',
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GColors.white),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('STEP 5 OF 5', style: GText.mono(Colors.white.withValues(alpha: 0.78), size: 11)),
                  const SizedBox(height: 20),
                  Container(
                    width: 208,
                    height: 208,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person_rounded, size: 92, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 22),
                  Text('One clear photo of your face',
                      textAlign: TextAlign.center, style: GText.title(GColors.white).copyWith(fontSize: 21)),
                  const SizedBox(height: 10),
                  Text(
                    'People need to recognise you from across a room. No sunglasses, no group shots.',
                    textAlign: TextAlign.center,
                    style: GText.body(Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Library',
                          background: GColors.white,
                          foreground: GColors.ink,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PillButton(
                          label: 'Camera',
                          background: Colors.white.withValues(alpha: 0.22),
                          foreground: GColors.white,
                          border: Colors.white.withValues(alpha: 0.5),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          WavePanel(
            color: GColors.white,
            padding: EdgeInsets.fromLTRB(28, 40, 28, MediaQuery.paddingOf(context).bottom + 22),
            child: Column(
              children: [
                PillButton(
                  label: 'Finish',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.sight, (r) => false),
                ),
                const SizedBox(height: 12),
                Text('That was the last step.', style: GText.small(GColors.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
