import 'package:flutter/material.dart';

import '../models/models.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

/// Frame 13: two people you passed recently - pick one, or judge both at once.
class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final pool = state.recent;
          final a = pool.isNotEmpty ? pool[0] : null;
          final b = pool.length > 1 ? pool[1] : null;

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
                          SizedBox(width: fx(context, 100)),
                        ],
                      ),
                    ),
                    if (a == null || b == null)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
                            child: Text(
                              'No pair to compare right now',
                              textAlign: TextAlign.center,
                              style: GText.fig(context, 50, GColors.white),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      const Spacer(),
                      _Candidate(person: a),
                      SizedBox(height: fx(context, 50)),
                      _Candidate(person: b),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FigButton(
                            label: 'Pass both',
                            width: 420,
                            background: GColors.white.withValues(alpha: 0.25),
                            foreground: GColors.white,
                            fontSize: 42,
                            onTap: () async {
                              await state.pass(a.id);
                              await state.pass(b.id);
                            },
                          ),
                          SizedBox(width: fx(context, 40)),
                          FigButton(
                            label: 'Like both',
                            width: 420,
                            background: GColors.white,
                            foreground: GColors.cyan,
                            fontSize: 42,
                            onTap: () async {
                              final first = await state.like(a.id);
                              final second = await state.like(b.id);
                              if (!context.mounted) return;
                              if (first || second) {
                                state.open(first ? a.id : b.id);
                                Navigator.pushNamed(context, Routes.match);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: fx(context, 50)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Candidate extends StatelessWidget {
  const _Candidate({required this.person});

  final Profile person;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return GestureDetector(
      onTap: () {
        state.open(person.id);
        Navigator.pushNamed(context, Routes.person);
      },
      child: Column(
        children: [
          FigAvatar(
            size: 470,
            photoPath: person.photoPath,
            name: person.name,
            ringColor: GColors.white,
            ringWidth: 14,
            shadow: true,
          ),
          SizedBox(height: fx(context, 16)),
          Text(
            person.name + (person.age > 0 ? ' ' + person.age.toString() : ''),
            style: GText.fig(context, 44, GColors.white),
          ),
        ],
      ),
    );
  }
}
