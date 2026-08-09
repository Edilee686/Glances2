import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.of(context).refreshActivity());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final items = state.activity;
          return Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 16, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8EDF1))),
                ),
                child: Row(
                  children: [
                    RoundIconButton(
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GColors.muted),
                    ),
                    Text('Activity', style: GText.title(GColors.ink).copyWith(fontSize: 20)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _Empty(onLook: () => Navigator.maybePop(context))
                    : RefreshIndicator(
                        color: GColors.blue,
                        onRefresh: state.refreshActivity,
                        child: ListView.separated(
                          itemCount: items.length + 1,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F3F6)),
                          itemBuilder: (context, i) {
                            if (i == items.length) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(30, 22, 30, 30),
                                child: Text(
                                  'Swipe a row to remove it, or swipe left to block. Likes with no answer disappear after 7 days.',
                                  textAlign: TextAlign.center,
                                  style: GText.small(const Color(0xFFA3AEB8)),
                                ),
                              );
                            }
                            final item = items[i];
                            final person = state.personById(item.personId);
                            return Dismissible(
                              key: ValueKey(item.personId + item.kind.index.toString()),
                              background: Container(
                                color: GColors.danger,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete_outline_rounded, color: GColors.white),
                              ),
                              secondaryBackground: Container(
                                color: GColors.danger,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.block_rounded, color: GColors.white),
                              ),
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  state.api.block(item.personId);
                                } else {
                                  state.api.dismissEvent(item.personId, item.kind);
                                }
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                leading: SizedBox(
                                  width: 22,
                                  child: item.unread
                                      ? const Icon(Icons.circle, size: 10, color: GColors.orange)
                                      : const SizedBox.shrink(),
                                ),
                                title: Text(item.title, style: GText.strong(GColors.ink)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GText.small(const Color(0xFF7B858E))),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.timeLabel, style: GText.mono(const Color(0xFFA3AEB8), size: 10.5)),
                                    const SizedBox(width: 10),
                                    PhotoCircle(
                                      diameter: 52,
                                      ringWidth: 0,
                                      shadow: false,
                                      name: person?.name,
                                      photoUrl: person?.photoUrl,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  state.openPerson(item.personId);
                                  state.api.markRead(item.personId);
                                  final matched = state.api.matched.contains(item.personId);
                                  Navigator.pushNamed(context, matched ? Routes.chat : Routes.person);
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onLook});

  final VoidCallback onLook;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: GColors.tint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.mail_outline_rounded, color: GColors.blue, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Nothing yet', style: GText.heading(GColors.ink).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Like someone in sight. If they look back, it shows up here.',
              textAlign: TextAlign.center,
              style: GText.body(GColors.muted),
            ),
            const SizedBox(height: 18),
            PillButton(label: 'Start looking', background: GColors.blue, onPressed: onLook),
          ],
        ),
      ),
    );
  }
}
