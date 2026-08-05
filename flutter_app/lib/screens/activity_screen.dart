import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: Column(
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
            child: FutureBuilder<List<ActivityItem>>(
              future: state.api.activity(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: GColors.blue));
                }
                final items = snapshot.data!;
                return ListView.separated(
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F3F6)),
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(30, 22, 30, 30),
                        child: Text(
                          'Swipe a row to block or delete. Likes with no answer disappear after 7 days.',
                          textAlign: TextAlign.center,
                          style: GText.small(const Color(0xFFA3AEB8)),
                        ),
                      );
                    }
                    final item = items[i];
                    return Dismissible(
                      key: ValueKey(item.personId + i.toString()),
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
                      onDismissed: (_) {},
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
                            const PhotoCircle(diameter: 52, ringWidth: 0, shadow: false),
                          ],
                        ),
                        onTap: () {
                          state.focusPerson(item.personId);
                          Navigator.pushNamed(context, Routes.chat);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
