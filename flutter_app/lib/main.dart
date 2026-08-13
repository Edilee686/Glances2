import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes.dart';
import 'screens/activity_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/join_screen.dart';
import 'screens/match_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/onboarding/birthday_screen.dart';
import 'screens/onboarding/gender_screen.dart';
import 'screens/onboarding/meet_screen.dart';
import 'screens/onboarding/name_screen.dart';
import 'screens/onboarding/photo_screen.dart';
import 'screens/person_screen.dart';
import 'screens/pick_screen.dart';
import 'screens/plus_screen.dart';
import 'screens/sight_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_screen.dart';
import 'services/auth.dart';
import 'services/db.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await GlancesDb.open();
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(db: db, auth: Auth(db, prefs));
  runApp(GlancesApp(state: state));
}

class GlancesApp extends StatelessWidget {
  const GlancesApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MaterialApp(
        title: 'Glances',
        debugShowCheckedModeBanner: false,
        theme: glancesTheme(),
        initialRoute: Routes.splash,
        routes: {
          Routes.splash: (_) => const SplashScreen(),
          Routes.join: (_) => const JoinScreen(),
          Routes.verify: (_) => const VerifyScreen(),
          Routes.name: (_) => const NameScreen(),
          Routes.gender: (_) => const GenderScreen(),
          Routes.meet: (_) => const MeetScreen(),
          Routes.birthday: (_) => const BirthdayScreen(),
          Routes.photo: (_) => const PhotoScreen(),
          Routes.sight: (_) => const SightScreen(),
          Routes.pick: (_) => const PickScreen(),
          Routes.person: (_) => const PersonScreen(),
          Routes.match: (_) => const MatchScreen(),
          Routes.activity: (_) => const ActivityScreen(),
          Routes.chat: (_) => const ChatScreen(),
          Routes.editProfile: (_) => const EditProfileScreen(),
          Routes.plus: (_) => const PlusScreen(),
          Routes.menu: (_) => const MenuScreen(),
        },
      ),
    );
  }
}
