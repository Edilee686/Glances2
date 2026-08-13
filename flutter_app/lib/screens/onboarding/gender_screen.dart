import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/onboarding_shell.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    final current = AppScope.read(context).me?.gender ?? '';
    _value = current.isEmpty ? null : current;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return OnboardingShell(
      prompt: 'What is your gender?',
      step: 2,
      onContinue: _value == null
          ? null
          : () async {
              await state.updateMe({'gender': _value});
              if (!context.mounted) return;
              Navigator.pushNamed(context, Routes.meet);
            },
      child: Column(
        children: [
          for (final option in const ['Woman', 'Man', 'Other'])
            ChoicePill(
              label: option,
              selected: _value == option,
              onTap: () => setState(() => _value = option),
            ),
        ],
      ),
    );
  }
}
