import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

/// The settings drawer as a full screen: profile card, discovery controls,
/// account actions.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final me = state.me;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: fx(context, 30), vertical: fx(context, 20)),
                  child: Row(
                    children: [
                      FigChevron(color: GColors.grey, onTap: () => Navigator.maybePop(context)),
                      const Spacer(),
                      const FigWordmark(color: GColors.grey),
                      const Spacer(),
                      SizedBox(width: fx(context, 100)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, Routes.editProfile),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: fx(context, 60), vertical: fx(context, 20)),
                    child: Row(
                      children: [
                        FigAvatar(
                          size: 200,
                          photoPath: me?.photoPath,
                          name: me?.name,
                          ringColor: GColors.white,
                          ringWidth: 8,
                          shadow: true,
                        ),
                        SizedBox(width: fx(context, 36)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                me == null || me.name.isEmpty ? 'Your profile' : me.headline,
                                style: GText.fig(context, 50, GColors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: fx(context, 8)),
                              Text('Edit profile',
                                  style: GText.fig(context, 36, GColors.cyan)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: GColors.circle, thickness: fx(context, 3)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: fx(context, 60)),
                    children: [
                      _Section(label: 'Line of sight - ' + state.rangeMeters.toString() + ' m'),
                      Slider(
                        value: state.rangeMeters.toDouble(),
                        min: 5,
                        max: 20,
                        divisions: 15,
                        activeColor: GColors.cyan,
                        inactiveColor: GColors.circle,
                        label: state.rangeMeters.toString() + ' m',
                        onChanged: (v) => state.setRange(v.round()),
                      ),
                      _Section(label: 'Recently seen - ' + state.withinMinutes.toString() + ' min'),
                      Slider(
                        value: state.withinMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: GColors.cyan,
                        inactiveColor: GColors.circle,
                        label: state.withinMinutes.toString() + ' min',
                        onChanged: (v) => state.setMinutes(v.round()),
                      ),
                      SizedBox(height: fx(context, 20)),
                      _Item(
                        label: 'Pick one of two',
                        onTap: () => Navigator.pushNamed(context, Routes.pick),
                      ),
                      _Item(
                        label: 'Likes and messages',
                        trailing: state.unread > 0 ? state.unread.toString() : null,
                        onTap: () => Navigator.pushNamed(context, Routes.activity),
                      ),
                      _Item(
                        label: state.plus ? 'Glances Plus - active' : 'Get Glances Plus',
                        onTap: () => Navigator.pushNamed(context, Routes.plus),
                      ),
                      Divider(color: GColors.circle, thickness: fx(context, 3)),
                      _Item(
                        label: 'Log out',
                        color: GColors.orange,
                        onTap: () => _confirm(
                          context,
                          state,
                          title: 'Log out?',
                          body: 'Your account stays on this device. You can sign back in.',
                          destructive: false,
                        ),
                      ),
                      _Item(
                        label: 'Delete account',
                        color: const Color(0xFFC0392B),
                        onTap: () => _confirm(
                          context,
                          state,
                          title: 'Delete account?',
                          body: 'Your profile, likes and chats are erased from this device.',
                          destructive: true,
                        ),
                      ),
                      SizedBox(height: fx(context, 60)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    AppState state, {
    required String title,
    required String body,
    required bool destructive,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: GColors.white,
        title: Text(title, style: GText.fig(context, 50, GColors.grey)),
        content: Text(body, style: GText.fig(context, 38, GColors.greyLine, height: 1.35)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text('Cancel', style: GText.fig(context, 42, GColors.greyLine)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text('Confirm', style: GText.fig(context, 42, GColors.cyan)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (destructive) {
      await state.deleteAccount();
    } else {
      await state.signOut();
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (route) => false);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: fx(context, 30), bottom: fx(context, 6)),
      child: Text(label, style: GText.fig(context, 40, GColors.grey)),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.onTap,
    this.color = GColors.grey,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fx(context, 34)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: GText.fig(context, 46, color))),
            if (trailing != null)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: fx(context, 22), vertical: fx(context, 6)),
                decoration: const BoxDecoration(
                  color: GColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(trailing!, style: GText.fig(context, 30, GColors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
