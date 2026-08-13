import 'package:flutter/material.dart';

import '../theme.dart';
import 'fig.dart';

/// Shared frame for the five onboarding steps: cyan curved sheet, wordmark,
/// prompt, content, and the Continue pill pinned to the bottom.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.prompt,
    required this.step,
    required this.child,
    required this.onContinue,
    this.footnote,
    this.subhead,
  });

  final String prompt;
  final int step;
  final Widget child;
  final VoidCallback? onContinue;
  final String? footnote;
  final String? subhead;

  static const steps = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.78,
            width: double.infinity,
            child: const CurvedSheet(color: GColors.cyan, bulge: 0.145),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      fx(context, 30), fx(context, 30), fx(context, 30), 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FigWordmark(),
                      Text(
                        step.toString() + ' of ' + steps.toString(),
                        style: GText.fig(context, 34, GColors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: fx(context, 90)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: fx(context, 80)),
                  child: Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: GText.fig(context, 50, GColors.white),
                  ),
                ),
                if (subhead != null) ...[
                  SizedBox(height: fx(context, 20)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: fx(context, 80)),
                    child: Text(
                      subhead!,
                      textAlign: TextAlign.center,
                      style: GText.fig(context, 36, GColors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
                    child: Column(children: [SizedBox(height: fx(context, 80)), child]),
                  ),
                ),
                if (footnote != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
                    child: Text(
                      footnote!,
                      textAlign: TextAlign.center,
                      style: GText.fig(context, 34, GColors.grey),
                    ),
                  ),
                  SizedBox(height: fx(context, 30)),
                ],
                FigButton(
                  label: 'Continue',
                  background: GColors.cyan,
                  onTap: onContinue,
                ),
                SizedBox(height: fx(context, 60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A white pill used for single-choice answers (gender, who to meet).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: fx(context, 36)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: fx(context, 880),
          height: fx(context, 120),
          decoration: BoxDecoration(
            color: selected ? GColors.white : GColors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(fx(context, 60)),
            border: Border.all(color: GColors.white, width: fx(context, 3)),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: Offset(fx(context, 4), fx(context, 8)),
                      blurRadius: fx(context, 16),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GText.fig(context, 46, selected ? GColors.cyan : GColors.white),
          ),
        ),
      ),
    );
  }
}
