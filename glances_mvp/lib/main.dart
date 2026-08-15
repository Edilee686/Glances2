import 'package:flutter/material.dart';

import 'session.dart';
import 'theme.dart';
import 'screens/auth.dart';
import 'screens/discovery.dart';
import 'screens/onboarding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlancesApp());
}

class GlancesApp extends StatefulWidget {
  const GlancesApp({super.key});
  @override
  State<GlancesApp> createState() => _GlancesAppState();
}

class _GlancesAppState extends State<GlancesApp> {
  @override
  void initState() {
    super.initState();
    Session.instance.boot();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glances',
      debugShowCheckedModeBanner: false,
      theme: glancesTheme(),
      home: AnimatedBuilder(
        animation: Session.instance,
        builder: (_, __) {
          final s = Session.instance;

          if (s.booting) return const _Splash();
          if (!s.signedIn) return const AuthScreen();

          // The API rejects discovery until a profile, settings and a photo
          // exist, so finish onboarding before showing the main screen.
          if (!(s.me?.onboarded ?? false)) return const OnboardingScreen();

          return const DiscoveryScreen();
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: GlancesColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GLANCES',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text('See. Like. Date',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 32),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
}
