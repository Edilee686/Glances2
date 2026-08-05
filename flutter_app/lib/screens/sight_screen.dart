import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/photo_circle.dart';
import '../widgets/range_row.dart';
import '../widgets/wave.dart';
import 'app_drawer.dart';

/// The core screen: everyone within line of sight, right now.
class SightScreen extends StatelessWidget {
  const SightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.blue,
      drawer: const AppDrawer(),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return Column(
            children: [
              const AppHeader(onDark: true, unread: 2),
              Text('In sight right now', style: GText.heading(GColors.white).copyWith(fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                state.inSightCount.toString() + ' PEOPLE WITHIN ' + state.rangeMeters.toString() + ' M',
                style: GText.mono(Colors.white.withValues(alpha: 0.85), size: 11.5),
                maxLines: 1,
              ),
              Expanded(
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v < -120) state.advance();
                    if (v > 120) state.rewind();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 4,
                        child: _Peek(name: state.previous.name, onTap: state.rewind, alignTop: true),
                      ),
                      Positioned(
                        bottom: 4,
                        child: _Peek(name: state.next.name, onTap: state.advance, alignTop: false),
                      ),
                      _Focused(state: state),
                    ],
                  ),
                ),
              ),
              WavePanel(
                color: GColors.white,
                padding: EdgeInsets.fromLTRB(24, 30, 24, MediaQuery.paddingOf(context).bottom + 20),
                child: RangeRow(
                  minLabel: '5 m',
                  maxLabel: '20 m',
                  min: 5,
                  max: 20,
                  value: state.rangeMeters.toDouble(),
                  caption: 'LINE OF SIGHT - ' + state.rangeMeters.toString() + ' M',
                  onChanged: (v) => state.setRange(v.round()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Peek extends StatelessWidget {
  const _Peek({required this.name, required this.onTap, required this.alignTop});

  final String name;
  final VoidCallback onTap;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Show ' + name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 196,
          height: 196,
          alignment: alignTop ? Alignment.topCenter : Alignment.bottomCenter,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
          ),
          child: Text(name, style: GText.label(GColors.white)),
        ),
      ),
    );
  }
}

class _Focused extends StatelessWidget {
  const _Focused({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final person = state.current;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, Routes.person),
      child: SizedBox(
        width: 264,
        height: 264,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            PhotoCircle(diameter: 248, photoUrl: person.photoUrl, ringColor: Colors.white.withValues(alpha: 0.35), ringWidth: 8),
            Positioned(
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: GColors.deep, borderRadius: BorderRadius.circular(999)),
                child: Text(person.name + ', ' + person.age.toString(),
                    style: GText.strong(GColors.white).copyWith(fontSize: 13), maxLines: 1),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 26,
              child: Semantics(
                button: true,
                label: 'Like ' + person.name,
                child: GestureDetector(
                  onTap: () async {
                    final mutual = await state.api.like(person.id);
                    if (!context.mounted) return;
                    if (mutual) {
                      Navigator.pushNamed(context, Routes.match);
                    } else {
                      state.advance();
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GColors.white,
                      boxShadow: [
                        BoxShadow(color: GColors.deep.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset('assets/images/mark.png', width: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
