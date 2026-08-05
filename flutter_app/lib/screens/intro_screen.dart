import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/wave.dart';

const introLines = [
  'See each other in reality',
  'Send a like - only mutual shows',
  'Start a conversation',
  'Get together and date',
];

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final controller = PageController();
  int index = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: Column(
        children: [
          Expanded(
            child: ClipPath(
              clipper: WaveClipper(fromTop: false, depth: 40),
              child: Container(
                color: GColors.blue,
                padding: EdgeInsets.fromLTRB(28, MediaQuery.paddingOf(context).top + 24, 28, 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: introLines.length,
                        onPageChanged: (i) => setState(() => index = i),
                        itemBuilder: (context, i) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Image.asset('assets/images/mark.png', width: 92),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                introLines[i],
                                textAlign: TextAlign.center,
                                style: GText.title(GColors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(introLines.length, (i) {
                        final active = i == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.5),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? GColors.white : Colors.transparent,
                            border: Border.all(color: GColors.white, width: 1.5),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28, 22, 28, MediaQuery.paddingOf(context).bottom + 24),
            child: Column(
              children: [
                PillButton(
                  label: 'Continue with Facebook',
                  background: GColors.white,
                  foreground: GColors.ink,
                  border: GColors.line,
                  icon: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: const Color(0xFF1877F2), borderRadius: BorderRadius.circular(5)),
                    alignment: Alignment.center,
                    child: Text('f', style: GText.strong(GColors.white)),
                  ),
                  onPressed: () {
                    state.set(() => state.introSlide = index);
                    Navigator.pushNamed(context, Routes.name);
                  },
                ),
                const SizedBox(height: 12),
                PillButton(label: 'Join with email', onPressed: () => Navigator.pushNamed(context, Routes.name)),
                const SizedBox(height: 14),
                Text('Terms and Conditions - Privacy Policy',
                    style: GText.small(GColors.faint), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
