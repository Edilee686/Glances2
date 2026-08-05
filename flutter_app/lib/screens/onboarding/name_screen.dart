import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'step_scaffold.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController controller = TextEditingController();
  bool seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!seeded) {
      controller.text = AppScope.of(context).name;
      seeded = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StepScaffold(
      step: 1,
      question: 'What should we call you?',
      footnote: 'This is the only name others see.',
      onContinue: () {
        state.set(() => state.name = controller.text.trim());
        Navigator.pushNamed(context, Routes.gender);
      },
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        style: GText.title(GColors.ink).copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          hintText: 'Your name',
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: GColors.blue, width: 2)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: GColors.blue, width: 2)),
        ),
      ),
    );
  }
}
