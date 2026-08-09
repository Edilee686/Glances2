import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      // Returning users go straight in; the profile they built is still there.
      final onboarded = AppScope.of(context).onboarded;
      Navigator.pushReplacementNamed(context, onboarded ? Routes.sight : Routes.intro);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GColors.white, GColors.white, Color(0xFFDFF2FC)],
            stops: [0, 0.34, 1],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GLANCES', style: GText.display(GColors.orange).copyWith(fontSize: 44)),
              const SizedBox(height: 6),
              Text('See. Like. Date.', style: GText.strong(GColors.blue)),
              const SizedBox(height: 24),
              Image.asset('assets/images/mark.png', width: 84),
            ],
          ),
        ),
      ),
    );
  }
}
