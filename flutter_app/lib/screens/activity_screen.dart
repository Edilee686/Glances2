import 'package:flutter/material.dart';

import '../models/models.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.of(context).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final rows = <_Row>[
            for (final m in state.matches) _Row(profile: m, kind: _Kind.match, otherId: m.id),
            for (final l in state.likeFeed)
              if (!state.matches.any((m) => m.id == l.otherId))
                _Row(
                  profile: _lookup(state, l.otherId),
                  kind: l.outgoing ? _Kind.youLiked : _Kind.likedYou,
                  fallbackName: l.otherName,
                  otherId: l.otherId,
                ),
          ];

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
                SizedBox(height: fx(context, 20)),
                Text('People you have probably met',
                    style: GText.fig(context, 50, GColors.grey)),
                SizedBox(height: fx(context, 30)),
                Expanded(
                  child: rows.isEmpty
                      ? _Empty(onBack: () => Navigator.maybePop(context))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: fx(context, 60)),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _ActivityTile(
                            row: rows[i],
                            onTap: () {
                              final id = rows[i].otherId;
                              if (id == null) return;
                              state.open(id);
                              Navigator.pushNamed(
                                context,
                                rows[i].kind == _Kind.match ? Routes.chat : Routes.person,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Profile? _lookup(AppState state, String id) {
    for (final p in [...state.nearby, ...state.recent, ...state.matches]) {
      if (p.id == id) return p;
    }
    return null;
  }
}

enum _Kind { match, likedYou, youLiked }

class _Row {
  _Row({required this.profile, required this.kind, this.fallbackName, this.otherId});

  final Profile? profile;
  final _Kind kind;
  final String? fallbackName;
  final String? otherId;

  String get name => profile?.name ?? fallbackName ?? '';
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row, required this.onTap});

  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (row.kind) {
      _Kind.match => 'Send her a message :)',
      _Kind.likedYou => 'You have got a like :)',
      _Kind.youLiked => 'Waiting for a mutual like..',
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fx(context, 24)),
        child: Row(
          children: [
            FigAvatar(
              size: 190,
              photoPath: row.profile?.photoPath,
              name: row.name,
              ringColor: GColors.white,
              ringWidth: 8,
              shadow: true,
            ),
            SizedBox(width: fx(context, 36)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name,
                      style: GText.fig(context, 46, GColors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: fx(context, 6)),
                  if (row.profile != null)
                    Text(row.profile!.metAtLabel,
                        style: GText.fig(context, 34, GColors.greyLine),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  SizedBox(height: fx(context, 6)),
                  Text(subtitle, style: GText.fig(context, 34, GColors.cyan)),
                ],
              ),
            ),
            if (row.kind == _Kind.match)
              Icon(Icons.chat_bubble_outline_rounded,
                  color: GColors.cyan, size: fx(context, 56)),
          ],
        ),
      ),
    );
  }
}

/// Frame 26: "No one had crossed your path yet".
class _Empty extends StatelessWidget {
  const _Empty({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FigAvatar(size: 460, ringColor: Color(0x14000000), ringWidth: 20),
            SizedBox(height: fx(context, 70)),
            Text('No one had crossed your path yet',
                textAlign: TextAlign.center, style: GText.fig(context, 50, GColors.grey)),
            SizedBox(height: fx(context, 50)),
            FigButton(label: 'Start looking', width: 620, onTap: onBack),
          ],
        ),
      ),
    );
  }
}
