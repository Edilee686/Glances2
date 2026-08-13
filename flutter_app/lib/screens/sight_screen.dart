import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_bar_row.dart';
import '../widgets/fig.dart';
import '../widgets/heart.dart';

/// The core screen. Everyone within range, stacked as overlapping circles that
/// scroll vertically under your thumb - the focused person sits on top.
class SightScreen extends StatefulWidget {
  const SightScreen({super.key});

  @override
  State<SightScreen> createState() => _SightScreenState();
}

class _SightScreenState extends State<SightScreen> {
  /// Figma: circles are 610 across and step about 366 apart, so each one
  /// overlaps its neighbour by roughly 40 percent.
  static const _diameter = 610.0;
  static const _stepRatio = 0.6;

  late final PageController _pages;
  double _page = 0;
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _page = state.carouselIndex.toDouble();
    _pages = PageController(
      initialPage: state.carouselIndex,
      viewportFraction: _stepRatio * 0.62,
    );
    _pages.addListener(() {
      if (!mounted) return;
      setState(() => _page = _pages.page ?? _page);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => state.refresh());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _like(AppState state, Profile person) async {
    final mutual = await state.like(person.id);
    if (!mounted) return;
    if (mutual) {
      Navigator.pushNamed(context, Routes.match);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: GColors.grey,
          content: Text(
            'Like sent to ' + person.name + '. They only find out if they like you back.',
            style: GText.fig(context, 34, GColors.white),
          ),
        ),
      );
    }
  }

  void _handleBack() {
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      Navigator.of(context).maybePop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Center(
          child: Text('Press BACK again to exit', style: GText.fig(context, 50, GColors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: GColors.white,
        body: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final people = state.nearby;
            return Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.93,
                  width: double.infinity,
                  child: const CurvedSheet(color: GColors.cyan, bulge: 0.115),
                ),
                if (people.isEmpty)
                  const _NobodyAround()
                else ...[
                  Positioned.fill(
                    child: _CircleStack(
                      people: people,
                      page: _page,
                      diameter: _diameter,
                      stepRatio: _stepRatio,
                    ),
                  ),
                  // Transparent pager: it owns the scroll gesture only.
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _pages,
                      scrollDirection: Axis.vertical,
                      itemCount: people.length,
                      onPageChanged: state.setCarousel,
                      itemBuilder: (context, i) => const SizedBox.expand(),
                    ),
                  ),
                  Positioned.fill(
                    child: _FocusedOverlay(
                      people: people,
                      page: _page,
                      diameter: _diameter,
                      onLike: (person) => _like(state, person),
                      onOpen: (person) {
                        state.open(person.id);
                        Navigator.pushNamed(context, Routes.person);
                      },
                    ),
                  ),
                ],
                SafeArea(
                  child: Column(
                    children: [
                      GlancesTopRow(state: state),
                      const Spacer(),
                      if (people.isNotEmpty)
                        Text(
                          people.length.toString() +
                              ' within ' +
                              state.rangeMeters.toString() +
                              ' m',
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
      ),
    );
  }
}

/// Draws every circle, nearest last so the focused person is on top.
class _CircleStack extends StatelessWidget {
  const _CircleStack({
    required this.people,
    required this.page,
    required this.diameter,
    required this.stepRatio,
  });

  final List<Profile> people;
  final double page;
  final double diameter;
  final double stepRatio;

  @override
  Widget build(BuildContext context) {
    final d = fx(context, diameter);
    final step = d * stepRatio;
    final order = List<int>.generate(people.length, (i) => i)
      ..sort((a, b) => (page - a).abs().compareTo((page - b).abs()));

    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final i in order.reversed)
            Builder(
              builder: (context) {
                final delta = i - page;
                if (delta.abs() > 2.6) return const SizedBox.shrink();
                final focus = (1 - delta.abs()).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, delta * step),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * focus,
                    child: FigAvatar(
                      size: diameter,
                      photoPath: people[i].photoPath,
                      name: people[i].name,
                      ringColor: GColors.white.withValues(alpha: 0.25),
                      ringWidth: 27,
                      dim: (1 - focus) * 0.06,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// The heart button and name label that belong to the focused circle only.
class _FocusedOverlay extends StatelessWidget {
  const _FocusedOverlay({
    required this.people,
    required this.page,
    required this.diameter,
    required this.onLike,
    required this.onOpen,
  });

  final List<Profile> people;
  final double page;
  final double diameter;
  final ValueChanged<Profile> onLike;
  final ValueChanged<Profile> onOpen;

  @override
  Widget build(BuildContext context) {
    final index = page.round().clamp(0, people.length - 1);
    final person = people[index];
    final settled = (page - index).abs() < 0.18;
    final d = fx(context, diameter);

    return IgnorePointer(
      ignoring: !settled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: settled ? 1 : 0,
        child: Center(
          child: SizedBox(
            width: d,
            height: d,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Tapping the face opens the full profile.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(person),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: fx(context, 40),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: fx(context, 34), vertical: fx(context, 12)),
                      decoration: BoxDecoration(
                        color: GColors.grey.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(fx(context, 40)),
                      ),
                      child: Text(
                        person.name +
                            (person.age > 0 ? ' ' + person.age.toString() : '') +
                            '  -  ' +
                            person.distanceM.toString() +
                            ' m',
                        style: GText.fig(context, 34, GColors.white),
                      ),
                    ),
                  ),
                ),
                // Figma places the heart at the lower right edge of the circle.
                Positioned(
                  right: -fx(context, 6),
                  bottom: fx(context, 78),
                  child: GestureDetector(
                    onTap: () => onLike(person),
                    child: Container(
                      width: fx(context, 150),
                      height: fx(context, 150),
                      decoration: BoxDecoration(
                        color: GColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: fx(context, 20),
                            offset: Offset(fx(context, 2), fx(context, 6)),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: TwoTonedHeart(size: fx(context, 76)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma Frame 16: "There's no one around you at the moment".
class _NobodyAround extends StatelessWidget {
  const _NobodyAround();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fx(context, 100)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -pi / 18,
              child: FigAvatar(
                size: 560,
                ringColor: GColors.white.withValues(alpha: 0.25),
                ringWidth: 27,
              ),
            ),
            SizedBox(height: fx(context, 80)),
            Text(
              'There is no one around you at the moment',
              textAlign: TextAlign.center,
              style: GText.fig(context, 50, GColors.white),
            ),
            SizedBox(height: fx(context, 40)),
            FigButton(
              label: 'Widen to 20 m',
              background: GColors.white,
              foreground: GColors.cyan,
              width: 620,
              onTap: () => state.setRange(20),
            ),
          ],
        ),
      ),
    );
  }
}
