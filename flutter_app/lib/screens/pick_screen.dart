import 'package:flutter/material.dart';

import '../models/person.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';
import '../widgets/range_row.dart';
import 'app_drawer.dart';

/// Pick one of two people seen in the last 30 minutes.
class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.surface,
      drawer: const AppDrawer(),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final a = state.pairA;
          final b = state.pairB;
          final hasPair = a != null && b != null;
          return Column(
            children: [
              ColoredBox(
                color: GColors.white,
                child: AppHeader(onDark: false, unread: state.unread),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Who did you just see?', style: GText.heading(GColors.ink)),
                          const SizedBox(height: 4),
                          Text('People near you in the last ' + state.withinMinutes.toString() + ' minutes.',
                              style: GText.small(GColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      tooltip: 'Skip this pair',
                      onTap: () => state.advance(2),
                      child: const Icon(Icons.replay_rounded, size: 20, color: GColors.faint),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: hasPair
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _Candidate(person: a!),
                            _Candidate(person: b!),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No pair right now', style: GText.heading(GColors.ink).copyWith(fontSize: 20)),
                              const SizedBox(height: 8),
                              Text(
                                'Stretch the time window, or head back to who is in sight.',
                                textAlign: TextAlign.center,
                                style: GText.body(GColors.muted),
                              ),
                              const SizedBox(height: 18),
                              PillButton(
                                label: 'Back to in sight',
                                background: GColors.blue,
                                onPressed: () {
                                  state.setMode(SightMode.inSight);
                                  Navigator.pushReplacementNamed(context, Routes.sight);
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: GColors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE8EDF1))),
                ),
                padding: EdgeInsets.fromLTRB(24, 10, 24, MediaQuery.paddingOf(context).bottom + 18),
                child: Column(
                  children: [
                    RangeRow(
                      minLabel: 'Now',
                      maxLabel: '30 min',
                      min: 0,
                      max: 30,
                      value: state.withinMinutes.toDouble(),
                      caption: state.withinMinutes.toString() + ' MIN AGO',
                      onChanged: (v) => state.setMinutes(v.round()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: 'Pass both',
                            background: GColors.white,
                            foreground: GColors.muted,
                            border: GColors.line,
                            onPressed: !hasPair
                                ? null
                                : () async {
                                    await state.api.pass(a!.id);
                                    await state.api.pass(b!.id);
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PillButton(
                            label: 'Like both',
                            background: hasPair ? GColors.orange : GColors.faint,
                            onPressed: !hasPair
                                ? null
                                : () async {
                                    final first = await state.api.like(a!.id);
                                    final second = await state.api.like(b!.id);
                                    if (!context.mounted) return;
                                    if (first || second) {
                                      state.openPerson(first ? a.id : b.id);
                                      Navigator.pushNamed(context, Routes.match);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
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

  final Person person;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Semantics(
      button: true,
      label: person.name + ', ' + person.age.toString(),
      child: GestureDetector(
        onTap: () {
          state.openPerson(person.id);
          Navigator.pushNamed(context, Routes.person);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            PhotoCircle(diameter: 214, photoUrl: person.photoUrl, name: person.name),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: GColors.deep, borderRadius: BorderRadius.circular(999)),
                child: Text(person.name + ', ' + person.age.toString(),
                    style: GText.label(GColors.white), maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
