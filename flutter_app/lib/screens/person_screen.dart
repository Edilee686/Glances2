import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final person = state.active;
          if (person == null) {
            return Center(
              child: FigButton(
                label: 'Back',
                width: 500,
                onTap: () => Navigator.maybePop(context),
              ),
            );
          }

          final people = state.nearby;
          final index = people.indexWhere((p) => p.id == person.id);
          final matched = state.matches.any((m) => m.id == person.id);
          final liked = state.likeFeed.any((l) => l.outgoing && l.otherId == person.id);

          return Stack(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.95,
                width: double.infinity,
                child: const CurvedSheet(color: GColors.cyan, bulge: 0.115),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: fx(context, 30), vertical: fx(context, 20)),
                      child: Row(
                        children: [
                          FigChevron(onTap: () => Navigator.maybePop(context)),
                          const Spacer(),
                          const FigWordmark(),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _sheet(context, state, person.id, person.name),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(fx(context, 22)),
                              child: Icon(Icons.more_horiz_rounded,
                                  color: GColors.white, size: fx(context, 70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FigChevron(
                          onTap: index > 0 ? () => state.open(people[index - 1].id) : null,
                          color: GColors.white.withValues(alpha: index > 0 ? 1 : 0.3),
                        ),
                        FigAvatar(
                          size: 760,
                          photoPath: person.photoPath,
                          name: person.name,
                          ringColor: GColors.white,
                          ringWidth: 20,
                          shadow: true,
                        ),
                        FigChevron(
                          left: false,
                          onTap: index >= 0 && index < people.length - 1
                              ? () => state.open(people[index + 1].id)
                              : null,
                          color: GColors.white
                              .withValues(alpha: index >= 0 && index < people.length - 1 ? 1 : 0.3),
                        ),
                      ],
                    ),
                    SizedBox(height: fx(context, 60)),
                    Text(person.headline, style: GText.fig(context, 50, GColors.white)),
                    SizedBox(height: fx(context, 12)),
                    Text(
                      person.distanceM.toString() + ' m away - seen ' + person.seenLabel,
                      style: GText.fig(context, 34, GColors.white.withValues(alpha: 0.85)),
                    ),
                    const Spacer(),
                    if (matched)
                      FigButton(
                        label: 'Open chat',
                        background: GColors.white,
                        foreground: GColors.cyan,
                        fontSize: 60,
                        onTap: () {
                          state.open(person.id);
                          Navigator.pushNamed(context, Routes.chat);
                        },
                      )
                    else if (liked)
                      FigButton(
                        label: 'Like already sent',
                        background: GColors.grey,
                        fontSize: 60,
                        onTap: null,
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await state.pass(person.id);
                              if (!context.mounted) return;
                              Navigator.maybePop(context);
                            },
                            child: Container(
                              width: fx(context, 150),
                              height: fx(context, 120),
                              alignment: Alignment.center,
                              child: Icon(Icons.close_rounded,
                                  color: GColors.white, size: fx(context, 72)),
                            ),
                          ),
                          SizedBox(width: fx(context, 20)),
                          FigButton(
                            label: 'Send a Like',
                            background: GColors.white,
                            foreground: GColors.cyan,
                            fontSize: 60,
                            width: 660,
                            onTap: () async {
                              final mutual = await state.like(person.id);
                              if (!context.mounted) return;
                              if (mutual) Navigator.pushReplacementNamed(context, Routes.match);
                            },
                          ),
                        ],
                      ),
                    SizedBox(height: fx(context, 40)),
                    Text(
                      matched
                          ? 'You both looked.'
                          : liked
                              ? 'Waiting for a mutual like..'
                              : person.name + ' only finds out if you both like.',
                      style: GText.fig(context, 40, GColors.grey),
                    ),
                    SizedBox(height: fx(context, 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sheet(BuildContext context, AppState state, String id, String name) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(fx(context, 60))),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: fx(context, 60), vertical: fx(context, 20)),
              leading: Icon(Icons.block_rounded, color: GColors.orange, size: fx(context, 64)),
              title: Text('Block ' + name, style: GText.fig(context, 46, GColors.grey)),
              onTap: () async {
                await state.block(id);
                if (!sheet.mounted) return;
                Navigator.pop(sheet);
                Navigator.maybePop(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: fx(context, 60), vertical: fx(context, 20)),
              leading: Icon(Icons.flag_outlined, color: GColors.grey, size: fx(context, 64)),
              title: Text('Report a problem', style: GText.fig(context, 46, GColors.grey)),
              onTap: () => Navigator.pop(sheet),
            ),
          ],
        ),
      ),
    );
  }
}
