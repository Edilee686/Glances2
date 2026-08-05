import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/wave.dart';

/// Shared chrome for the five onboarding steps: back arrow, step counter,
/// one question, and a wave-topped continue panel in the opposite colour.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.question,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.dark = false,
    this.footnote,
  });

  final int step;
  final String question;
  final Widget child;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool dark;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? GColors.blue : GColors.white;
    final panel = dark ? GColors.white : GColors.blue;
    final onBg = dark ? GColors.white : GColors.ink;
    final counter = dark ? Colors.white.withValues(alpha: 0.78) : GColors.blue;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 8, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RoundIconButton(
                tooltip: 'Back',
                onTap: () => Navigator.maybePop(context),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: onBg),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP ' + step.toString() + ' OF 5', style: GText.mono(counter, size: 11)),
                  const SizedBox(height: 10),
                  Text(question, style: GText.display(onBg)),
                  const SizedBox(height: 24),
                  child,
                  if (footnote != null) ...[
                    const SizedBox(height: 14),
                    Text(footnote!,
                        style: GText.small(dark ? Colors.white.withValues(alpha: 0.88) : GColors.faint)),
                  ],
                ],
              ),
            ),
          ),
          WavePanel(
            color: panel,
            padding: EdgeInsets.fromLTRB(28, 46, 28, MediaQuery.paddingOf(context).bottom + 28),
            child: PillButton(
              label: continueLabel,
              background: dark ? GColors.blue : GColors.white,
              foreground: dark ? GColors.white : GColors.ink,
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
