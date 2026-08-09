import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Drawer(
      backgroundColor: GColors.white,
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: GColors.blue,
            padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 20, 22, 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.35),
                    border: Border.all(color: GColors.white, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.name.isEmpty ? '?' : state.name.substring(0, 1).toUpperCase(),
                    style: GText.heading(GColors.white).copyWith(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.name + ', ' + state.age.toString(),
                          style: GText.heading(GColors.white).copyWith(fontSize: 17), overflow: TextOverflow.ellipsis),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, Routes.editProfile);
                        },
                        child: Text('Edit profile',
                            style: GText.small(Colors.white.withValues(alpha: 0.92))
                                .copyWith(decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _Toggle(
                  title: 'Invisibility',
                  description: 'Browse without appearing to anyone around you.',
                  value: state.invisibility,
                  onChanged: (v) => state.set(() => state.invisibility = v),
                ),
                _Toggle(
                  title: 'Show profile information',
                  description: 'City, height and the rest. Your photo always shows.',
                  value: state.showProfileInfo,
                  onChanged: (v) => state.set(() => state.showProfileInfo = v),
                ),
                const Divider(height: 24, indent: 22, endIndent: 22, color: Color(0xFFEDF1F4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INTERESTED IN', style: GText.label(GColors.faint)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final option in ['Men', 'Women', 'Both']) ...[
                            Expanded(
                              child: ChoiceChipPill(
                                label: option,
                                selected: state.interestedIn == option,
                                onTap: () => state.set(() => state.interestedIn = option),
                              ),
                            ),
                            if (option != 'Both') const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(state.ageRange.start.round().toString(), style: GText.mono(GColors.ink, size: 12)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RangeSlider(
                              values: state.ageRange,
                              min: 18,
                              max: 70,
                              activeColor: GColors.blue,
                              inactiveColor: GColors.line,
                              onChanged: (v) => state.set(() => state.ageRange = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(state.ageRange.end.round().toString(), style: GText.mono(GColors.ink, size: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24, indent: 22, endIndent: 22, color: Color(0xFFEDF1F4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Material(
                    color: GColors.deep,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.plus);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Glances Plus', style: GText.strong(GColors.white).copyWith(fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('Unlimited passes and like both',
                                      style: GText.small(Colors.white.withValues(alpha: 0.72)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: GColors.orange),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  minVerticalPadding: 12,
                  title: Text('Matches', style: GText.strong(GColors.ink)),
                  trailing: Text(state.matches.length.toString(), style: GText.mono(GColors.faint, size: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.activity);
                  },
                ),
                for (final item in const [
                  'Notifications',
                  'Invite friends',
                  'Share Glances',
                  'Contact us',
                  'Privacy policy and Terms of use',
                ])
                  ListTile(
                    minVerticalPadding: 12,
                    title: Text(item, style: GText.strong(GColors.ink)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: GColors.deep,
                          content: Text(item + ' is not wired up in this build.',
                              style: GText.small(GColors.white)),
                        ),
                      );
                    },
                  ),
                ListTile(
                  minVerticalPadding: 12,
                  title: Text('Log out', style: GText.strong(GColors.orange)),
                  onTap: () => _confirmReset(context, state,
                      title: 'Log out?', body: 'You will land back at the start.'),
                ),
                ListTile(
                  minVerticalPadding: 12,
                  title: Text('Delete account', style: GText.strong(GColors.danger)),
                  onTap: () => _confirmReset(context, state,
                      title: 'Delete account?',
                      body: 'Your profile, likes and chats on this device are erased.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Log out and delete both clear the local store and restart at the splash.
Future<void> _confirmReset(BuildContext context, AppState state,
    {required String title, required String body}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: GColors.white,
      title: Text(title, style: GText.strong(GColors.ink).copyWith(fontSize: 17)),
      content: Text(body, style: GText.body(GColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text('Cancel', style: GText.strong(GColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text('Confirm', style: GText.strong(GColors.danger)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await state.resetEverything();
  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil(Routes.splash, (route) => false);
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.description, required this.value, required this.onChanged});

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GText.strong(GColors.ink).copyWith(fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(description, style: GText.small(const Color(0xFF7B858E)).copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            Switch(value: value, activeColor: GColors.white, activeTrackColor: GColors.blue, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
