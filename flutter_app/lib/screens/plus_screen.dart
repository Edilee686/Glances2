import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';

class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  static const plans = [
    ['1 MONTH', '\u002415', 'Total \u002415'],
    ['3 MONTHS', '\u002412', 'Save 20%'],
    ['6 MONTHS', '\u002410', 'Save 33%'],
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.deep,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    tooltip: 'Close',
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text('GLANCES', style: GText.display(GColors.orange).copyWith(fontSize: 30)),
                        Text('PLUS', style: GText.mono(GColors.blue, size: 12).copyWith(letterSpacing: 4)),
                        const SizedBox(height: 18),
                        Container(
                          width: 124,
                          height: 124,
                          decoration: const BoxDecoration(color: GColors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Image.asset('assets/images/mark.png', width: 70),
                        ),
                        const SizedBox(height: 18),
                        Text('Unlimited passes and like both',
                            textAlign: TextAlign.center,
                            style: GText.title(GColors.white).copyWith(fontSize: 19)),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (var i = 0; i < plans.length; i++) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => state.set(() => state.planIndex = i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: state.planIndex == i
                                          ? GColors.orange.withValues(alpha: 0.14)
                                          : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: state.planIndex == i
                                            ? GColors.orange
                                            : Colors.white.withValues(alpha: 0.14),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(plans[i][0],
                                            style: GText.label(GColors.white).copyWith(fontSize: 11),
                                            maxLines: 1),
                                        const SizedBox(height: 6),
                                        Text(plans[i][1], style: GText.title(GColors.white).copyWith(fontSize: 18)),
                                        Text('per month',
                                            style: GText.small(Colors.white.withValues(alpha: 0.6))
                                                .copyWith(fontSize: 10.5)),
                                        const SizedBox(height: 8),
                                        Text(
                                          plans[i][2],
                                          maxLines: 1,
                                          style: GText.label(state.planIndex == i
                                                  ? GColors.orange
                                                  : Colors.white.withValues(alpha: 0.6))
                                              .copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (i < plans.length - 1) const SizedBox(width: 9),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                        _Benefit('See everyone who liked you'),
                        const SizedBox(height: 8),
                        _Benefit('Look back further than 30 minutes'),
                      ],
                    ),
                  ),
                ),
                PillButton(
                  label: 'Continue',
                  background: GColors.orange,
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text('No, thanks', style: GText.body(Colors.white.withValues(alpha: 0.55))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(color: GColors.orange, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GText.body(Colors.white.withValues(alpha: 0.85)).copyWith(fontSize: 13.5)),
        ),
      ],
    );
  }
}
