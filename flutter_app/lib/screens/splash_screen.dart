import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/heart.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final state = AppScope.of(context);
    await state.boot();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final me = state.me;
    if (!state.auth.signedIn) {
      Navigator.pushReplacementNamed(context, Routes.join);
    } else if (me == null || !me.onboarded) {
      Navigator.pushReplacementNamed(context, Routes.name);
    } else {
      Navigator.pushReplacementNamed(context, Routes.sight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GColors.white, GColors.gradientBottom],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GLANCES',
                style: GText.fig(context, 112, GColors.orange, weight: FontWeight.w600)
                    .copyWith(letterSpacing: fx(context, 6)),
              ),
              SizedBox(height: fx(context, 18)),
              Text('See. Like. Date', style: GText.fig(context, 40, GColors.blue)),
              SizedBox(height: fx(context, 60)),
              TwoTonedHeart(size: fx(context, 192)),
            ],
          ),
        ),
      ),
    );
  }
}
