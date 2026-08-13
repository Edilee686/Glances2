import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/onboarding_shell.dart';

class MeetScreen extends StatefulWidget {
  const MeetScreen({super.key});

  @override
  State<MeetScreen> createState() => _MeetScreenState();
}

class _MeetScreenState extends State<MeetScreen> {
  String? _value;

  @override
  void initState() {
    super.initState();
    final current = AppScope.read(context).me?.seeking ?? '';
    _value = current.isEmpty ? null : current;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return OnboardingShell(
      prompt: 'Who would you like to meet',
      step: 3,
      onContinue: _value == null
          ? null
          : () async {
              await state.updateMe({'seeking': _value});
              if (!context.mounted) return;
              Navigator.pushNamed(context, Routes.birthday);
            },
      child: Column(
        children: [
          for (final option in const ['Women', 'Men', 'Everyone'])
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
