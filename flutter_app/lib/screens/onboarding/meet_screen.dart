import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/buttons.dart';
import 'step_scaffold.dart';

class MeetScreen extends StatelessWidget {
  const MeetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StepScaffold(
      step: 3,
      question: 'Who would you like to meet?',
      onContinue: () => Navigator.pushNamed(context, Routes.birthday),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final option in ['Men', 'Women', 'Both']) ...[
                Expanded(
                  child: ChoiceChipPill(
                    label: option,
                    selected: state.interestedIn == option,
                    onTap: () => state.set(() => state.interestedIn = option),
                  ),
                ),
                if (option != 'Both') const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 30),
          Text('Age range', style: GText.strong(GColors.muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(state.ageRange.start.round().toString(), style: GText.mono(GColors.ink, size: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: RangeSlider(
                  values: state.ageRange,
                  min: 18,
                  max: 70,
                  activeColor: GColors.blue,
                  inactiveColor: GColors.line,
                  onChanged: (v) => state.set(() => state.ageRange = v),
                ),
              ),
              const SizedBox(width: 12),
              Text(state.ageRange.end.round().toString(), style: GText.mono(GColors.ink, size: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
