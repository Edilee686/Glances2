import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/buttons.dart';
import 'step_scaffold.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StepScaffold(
      step: 2,
      dark: true,
      question: 'I am',
      footnote: 'You can change this later, and choose whether it shows on your profile.',
      onContinue: () => Navigator.pushNamed(context, Routes.meet),
      child: Column(
        children: [
          for (final option in ['Man', 'Woman', 'Other']) ...[
            SizedBox(
              width: double.infinity,
              child: ChoiceChipPill(
                label: option,
                onDark: true,
                selected: state.gender == option,
                onTap: () => state.set(() => state.gender = option),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
