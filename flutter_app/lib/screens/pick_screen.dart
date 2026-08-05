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
          return Column(
            children: [
              ColoredBox(
                color: GColors.white,
                child: const AppHeader(onDark: false, unread: 2),
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
                      tooltip: 'Undo last pick',
                      onTap: () => state.rewind(2),
                      child: const Icon(Icons.replay_rounded, size: 20, color: GColors.faint),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Candidate(person: state.pairA),
                      _Candidate(person: state.pairB),
                    ],
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
                            onPressed: () => state.advance(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PillButton(
                            label: 'Like both',
                            background: GColors.orange,
                            onPressed: () => Navigator.pushNamed(context, Routes.match),
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
          state.focusPerson(person.id);
          Navigator.pushNamed(context, Routes.person);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            PhotoCircle(diameter: 214, photoUrl: person.photoUrl),
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
