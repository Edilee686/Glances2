import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/onboarding_shell.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = AppScope.read(context).me?.birthday;
  }

  int get _age {
    final b = _value;
    if (b == null) return 0;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) years--;
    return years;
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _value ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'What is your date of birth?',
    );
    if (picked != null) setState(() => _value = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final value = _value;
    return OnboardingShell(
      prompt: 'What is your date of birth?',
      subhead: 'One more step and we are done..!',
      step: 4,
      footnote: 'You must be at least 18 years old to join Glances',
      onContinue: value == null || _age < 18
          ? null
          : () async {
              await state.updateMe({'birthday': value.millisecondsSinceEpoch});
              if (!context.mounted) return;
              Navigator.pushNamed(context, Routes.photo);
            },
      child: GestureDetector(
        onTap: _pick,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: fx(context, 40)),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: GColors.white.withValues(alpha: 0.6), width: 2),
            ),
          ),
          child: Text(
            value == null
                ? 'Tap to choose'
                : value.day.toString() + ' ' + _months[value.month - 1] + ' ' + value.year.toString(),
            textAlign: TextAlign.center,
            style: GText.fig(
              context,
              60,
              value == null ? GColors.white.withValues(alpha: 0.5) : GColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
