import 'package:flutter/material.dart';

import '../models/person.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_header.dart';
import '../widgets/photo_circle.dart';
import '../widgets/range_row.dart';
import '../widgets/wave.dart';
import 'app_drawer.dart';

/// The core screen: everyone within line of sight, right now, as a vertical
/// carousel you scroll through with your thumb.
class SightScreen extends StatefulWidget {
  const SightScreen({super.key});

  @override
  State<SightScreen> createState() => _SightScreenState();
}

class _SightScreenState extends State<SightScreen> {
  static const _viewportFraction = 0.66;

  late final PageController _pages;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    final state = AppScope.of(context);
    final len = state.people.length;
    final start = len == 0 ? 0 : state.cursor % len;
    _page = start.toDouble();
    _pages = PageController(initialPage: start, viewportFraction: _viewportFraction);
    _pages.addListener(() {
      if (!mounted) return;
      setState(() => _page = _pages.page ?? _page);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _jump(int delta) {
    final target = (_pages.page ?? 0).round() + delta;
    if (target < 0) return;
    _pages.animateToPage(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.blue,
      drawer: const AppDrawer(),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final people = state.people;
          return Column(
            children: [
              AppHeader(onDark: true, unread: state.unread),
              Text('In sight right now', style: GText.heading(GColors.white).copyWith(fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                people.isEmpty
                    ? 'NOBODY WITHIN ' + state.rangeMeters.toString() + ' M'
                    : people.length.toString() + ' PEOPLE WITHIN ' + state.rangeMeters.toString() + ' M',
                style: GText.mono(Colors.white.withValues(alpha: 0.85), size: 11.5),
                maxLines: 1,
              ),
              Expanded(
                child: people.isEmpty
                    ? _Empty(onWiden: () => state.setRange(20))
                    : _Carousel(
                        controller: _pages,
                        page: _page,
                        people: people,
                        onPageChanged: (i) => state.setCursor(i),
                        onLike: (person) async {
                          state.openPerson(person.id);
                          final mutual = await state.likeActive();
                          if (!context.mounted) return;
                          if (mutual) {
                            Navigator.pushNamed(context, Routes.match);
                          } else {
                            _jump(1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: GColors.deep,
                                content: Text('Liked ' + person.name + ' - they only find out if they like you too',
                                    style: GText.small(GColors.white)),
                              ),
                            );
                          }
                        },
                        onOpen: (person) {
                          state.openPerson(person.id);
                          Navigator.pushNamed(context, Routes.person);
                        },
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

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.controller,
    required this.page,
    required this.people,
    required this.onPageChanged,
    required this.onLike,
    required this.onOpen,
  });

  final PageController controller;
  final double page;
  final List<Person> people;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Person> onLike;
  final ValueChanged<Person> onOpen;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      scrollDirection: Axis.vertical,
      onPageChanged: onPageChanged,
      itemCount: people.length,
      padEnds: true,
      itemBuilder: (context, i) {
        final person = people[i];
        final distance = (page - i).abs().clamp(0.0, 1.0);
        final scale = 1 - distance * 0.32;
        final fade = 1 - distance * 0.55;
        final focused = distance < 0.5;
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: fade,
              child: _Card(
                person: person,
                focused: focused,
                onLike: () => onLike(person),
                onOpen: () => onOpen(person),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.person, required this.focused, required this.onLike, required this.onOpen});

  final Person person;
  final bool focused;
  final VoidCallback onLike;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final diameter = (width * 0.66).clamp(200.0, 268.0);
    return GestureDetector(
      onTap: onOpen,
      child: SizedBox(
        width: diameter + 16,
        height: diameter + 16,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            PhotoCircle(
              diameter: diameter,
              photoUrl: person.photoUrl,
              name: person.name,
              ringColor: Colors.white.withValues(alpha: focused ? 0.4 : 0.22),
              ringWidth: 8,
            ),
            Positioned(
              bottom: 26,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: GColors.deep, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  person.name + ', ' + person.age.toString() + '  -  ' + person.distanceLabel,
                  style: GText.strong(GColors.white).copyWith(fontSize: 13),
                  maxLines: 1,
                ),
              ),
            ),
            if (focused)
              Positioned(
                right: -2,
                bottom: 22,
                child: Semantics(
                  button: true,
                  label: 'Like ' + person.name,
                  child: GestureDetector(
                    onTap: onLike,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: GColors.deep.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.onWiden});

  final VoidCallback onWiden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.visibility_off_rounded, color: Colors.white.withValues(alpha: 0.7), size: 44),
            ),
            const SizedBox(height: 22),
            Text('Nobody in sight', style: GText.heading(GColors.white).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Widen your line of sight, or wait for someone to walk past.',
              textAlign: TextAlign.center,
              style: GText.body(Colors.white.withValues(alpha: 0.86)),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onWiden,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              child: Text('Widen to 20 m', style: GText.strong(GColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
