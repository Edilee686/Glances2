import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final fields = <List<String>>[
      ['Name', state.name],
      ['Location', 'Netanya'],
      ['Gender', state.gender],
      ['Birthday', '2 November 1988'],
      ['Height', '171 cm'],
      ['Hair', 'Blond'],
      ['Eyes', 'Green'],
    ];

    return Scaffold(
      backgroundColor: GColors.surface,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 16, 8),
            decoration: const BoxDecoration(
              color: GColors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE8EDF1))),
            ),
            child: Row(
              children: [
                RoundIconButton(
                  tooltip: 'Back',
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GColors.muted),
                ),
                Expanded(child: Text('Edit profile', style: GText.title(GColors.ink).copyWith(fontSize: 20))),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text('Save', style: GText.strong(GColors.blue)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhotoCircle(diameter: 132),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _AddPhoto(),
                          const SizedBox(height: 12),
                          _AddPhoto(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: GColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EDF1)),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < fields.length; i++)
                        Container(
                          decoration: BoxDecoration(
                            border: i == fields.length - 1
                                ? null
                                : const Border(bottom: BorderSide(color: Color(0xFFF0F3F6))),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(width: 84, child: Text(fields[i][0], style: GText.label(GColors.faint))),
                              Expanded(child: Text(fields[i][1], style: GText.strong(GColors.ink))),
                              const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFC6CFD6)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Details you leave blank simply do not appear on your profile.',
                    style: GText.small(GColors.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DottedBox(
      child: SizedBox(
        height: 60,
        child: Center(child: Icon(Icons.add_rounded, color: const Color(0xFFB4BDC5), size: 22)),
      ),
    );
  }
}

class DottedBox extends StatelessWidget {
  const DottedBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCFD8E0), width: 1.5),
      ),
      child: child,
    );
  }
}
