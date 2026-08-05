import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'step_scaffold.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  static const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  late DateTime value = AppScope.of(context).birthday;

  bool get isAdult {
    final now = DateTime.now();
    final eighteenth = DateTime(value.year + 18, value.month, value.day);
    return !eighteenth.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StepScaffold(
      step: 4,
      dark: true,
      question: 'When were you born?',
      footnote: isAdult ? 'You must be 18 or older to join Glances.' : 'Glances is for adults only - you must be 18+.',
      onContinue: () {
        if (!isAdult) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be 18 or older to join Glances.')),
          );
          return;
        }
        state.set(() => state.birthday = value);
        Navigator.pushNamed(context, Routes.photo);
      },
      child: Container(
        decoration: BoxDecoration(color: GColors.white, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        height: 168,
        child: Row(
          children: [
            Expanded(
              child: _Wheel(
                count: 31,
                initial: value.day - 1,
                label: (i) => (i + 1).toString().padLeft(2, '0'),
                onChanged: (i) => setState(() => value = DateTime(value.year, value.month, i + 1)),
              ),
            ),
            Expanded(
              flex: 2,
              child: _Wheel(
                count: 12,
                initial: value.month - 1,
                label: (i) => months[i],
                onChanged: (i) => setState(() => value = DateTime(value.year, i + 1, value.day)),
              ),
            ),
            Expanded(
              flex: 2,
              child: _Wheel(
                count: 80,
                initial: value.year - 1946,
                label: (i) => (1946 + i).toString(),
                onChanged: (i) => setState(() => value = DateTime(1946 + i, value.month, value.day)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.count, required this.initial, required this.label, required this.onChanged});

  final int count;
  final int initial;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 44,
      diameterRatio: 1.8,
      physics: const FixedExtentScrollPhysics(),
      controller: FixedExtentScrollController(initialItem: initial.clamp(0, count - 1)),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, i) => Center(
          child: Text(label(i), style: GText.title(GColors.ink).copyWith(fontSize: 21)),
        ),
      ),
    );
  }
}
