import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

/// Enter the six digit code. There is no SMS gateway in this build, so the code
/// is shown on screen - wire your provider into Auth.requestCode to send it.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = AppScope.of(context);
    final result = await state.auth.verifyCode(_controller.text);
    if (result == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'That code did not match. Try again.';
      });
      return;
    }
    await state.boot();
    if (!mounted) return;
    final me = state.me;
    Navigator.pushNamedAndRemoveUntil(
      context,
      result.isNew || me == null || !me.onboarded ? Routes.name : Routes.sight,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.cyan,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: fx(context, 30), top: fx(context, 30)),
              child: const Align(alignment: Alignment.centerLeft, child: FigWordmark()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
                child: Column(
                  children: [
                    SizedBox(height: fx(context, 200)),
                    Text(
                      'Enter the code we sent to',
                      textAlign: TextAlign.center,
                      style: GText.fig(context, 50, GColors.white),
                    ),
                    SizedBox(height: fx(context, 16)),
                    Text(
                      state.auth.pendingPhone ?? '',
                      style: GText.fig(context, 44, GColors.white.withValues(alpha: 0.85)),
                    ),
                    SizedBox(height: fx(context, 80)),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: GText.fig(context, 90, GColors.white, weight: FontWeight.w600)
                          .copyWith(letterSpacing: fx(context, 20)),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: GText.fig(context, 90, GColors.white.withValues(alpha: 0.4))
                            .copyWith(letterSpacing: fx(context, 20)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: GColors.white.withValues(alpha: 0.6), width: 2),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: GColors.white, width: 3),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: fx(context, 24)),
                      Text(_error!, style: GText.fig(context, 36, GColors.white)),
                    ],
                    SizedBox(height: fx(context, 50)),
                    if (state.auth.lastCode != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: fx(context, 40), vertical: fx(context, 24)),
                        decoration: BoxDecoration(
                          color: GColors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(fx(context, 24)),
                        ),
                        child: Text(
                          'No SMS gateway in this build.\nYour code is ' + state.auth.lastCode!,
                          textAlign: TextAlign.center,
                          style: GText.fig(context, 34, GColors.white, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            FigButton(
              label: 'Continue',
              background: GColors.white,
              foreground: GColors.cyan,
              onTap: _busy ? null : _submit,
            ),
            SizedBox(height: fx(context, 60)),
          ],
        ),
      ),
    );
  }
}
