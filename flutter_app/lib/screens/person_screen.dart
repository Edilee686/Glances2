import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';
import '../widgets/range_row.dart';

class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.surface,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final person = state.activePerson;
          if (person == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nobody here', style: GText.heading(GColors.ink)),
                    const SizedBox(height: 8),
                    Text('That person moved out of range.',
                        textAlign: TextAlign.center, style: GText.body(GColors.muted)),
                    const SizedBox(height: 18),
                    PillButton(
                      label: 'Back to in sight',
                      background: GColors.blue,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ),
            );
          }
          final people = state.people;
          final index = people.indexWhere((p) => p.id == person.id) + 1;
          return Column(
            children: [
              Container(
                color: GColors.white,
                padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 8, 8),
                child: Row(
                  children: [
                    RoundIconButton(
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GColors.muted),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          (index < 1 ? 1 : index).toString() + ' of ' + people.length.toString() + ' nearby',
                          style: GText.strong(GColors.ink).copyWith(fontSize: 14),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    RoundIconButton(
                      tooltip: 'Report or block',
                      onTap: () => _showReport(context, state, person.id, person.name),
                      child: const Icon(Icons.more_horiz_rounded, color: GColors.faint),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RoundIconButton(
                              tooltip: 'Previous',
                              background: GColors.white,
                              onTap: () {
                                state.rewind();
                                final p = state.current;
                                if (p != null) state.openPerson(p.id);
                              },
                              child: const Icon(Icons.chevron_left_rounded, color: GColors.muted),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: PhotoCircle(diameter: 236, photoUrl: person.photoUrl, name: person.name),
                            ),
                            const SizedBox(width: 8),
                            RoundIconButton(
                              tooltip: 'Next',
                              background: GColors.white,
                              onTap: () {
                                state.advance();
                                final p = state.current;
                                if (p != null) state.openPerson(p.id);
                              },
                              child: const Icon(Icons.chevron_right_rounded, color: GColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(person.name + ', ' + person.age.toString(), style: GText.title(GColors.ink)),
                        const SizedBox(height: 4),
                        if (state.showProfileInfo) Text(person.city, style: GText.body(GColors.muted)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: GColors.tint, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(color: GColors.green, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                person.distanceLabel + ' away - ' + person.seenLabel,
                                style: GText.mono(GColors.deep),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (state.api.matched.contains(person.id)) ...[
                          const SizedBox(height: 14),
                          PillButton(
                            label: 'Open chat',
                            background: GColors.blue,
                            onPressed: () => Navigator.pushNamed(context, Routes.chat),
                          ),
                        ],
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
                      onChanged: (v) => state.setMinutes(v.round()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RoundIconButton(
                          tooltip: 'Pass',
                          size: 54,
                          onTap: () async {
                            await state.passActive();
                            if (!context.mounted) return;
                            Navigator.maybePop(context);
                          },
                          child: const Icon(Icons.close_rounded, color: GColors.faint),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PillButton(
                            label: state.api.liked.contains(person.id) ? 'Liked' : 'Like',
                            background: state.api.liked.contains(person.id) ? GColors.faint : GColors.orange,
                            onPressed: state.api.liked.contains(person.id)
                                ? null
                                : () async {
                                    final mutual = await state.likeActive();
                                    if (!context.mounted) return;
                                    if (mutual) Navigator.pushNamed(context, Routes.match);
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(person.name + ' only finds out if you both like.',
                        style: GText.small(GColors.faint), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReport(BuildContext context, AppState state, String id, String name) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block_rounded, color: GColors.danger),
              title: Text('Block ' + name, style: GText.strong(GColors.ink)),
              onTap: () {
                state.api.block(id);
                Navigator.pop(sheet);
                Navigator.maybePop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: GColors.muted),
              title: Text('Report a problem', style: GText.strong(GColors.ink)),
              onTap: () {
                Navigator.pop(sheet);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: GColors.deep,
                    content: Text('Report sent. We will look into it.', style: GText.small(GColors.white)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
