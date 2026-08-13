import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/onboarding_shell.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppScope.read(context).me?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return OnboardingShell(
      prompt: 'Please insert your name',
      step: 1,
      onContinue: _controller.text.trim().isEmpty
          ? null
          : () async {
              await state.updateMe({'name': _controller.text.trim()});
              if (!context.mounted) return;
              Navigator.pushNamed(context, Routes.gender);
            },
      child: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        style: GText.fig(context, 60, GColors.white),
        decoration: InputDecoration(
          hintText: 'Kathrine',
          hintStyle: GText.fig(context, 60, GColors.white.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: GColors.white.withValues(alpha: 0.6), width: 2),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: GColors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
