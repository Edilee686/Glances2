import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedBuilder(animation: state, builder: (context, _) => _build(context, state));
  }

  Widget _build(BuildContext context, AppState state) {
    final fields = <List<String>>[
      ['Name', state.name],
      ['Gender', state.gender],
      [
        'Birthday',
        state.birthday.day.toString() + ' ' + _months[state.birthday.month - 1] + ' ' + state.birthday.year.toString()
      ],
      ['Age', state.age.toString()],
      ['Interested in', state.interestedIn],
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
                  onPressed: () {
                    Navigator.maybePop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: GColors.deep,
                        content: Text('Profile saved.', style: GText.small(GColors.white)),
                      ),
                    );
                  },
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
                    PhotoCircle(diameter: 132, name: state.name),
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
                        InkWell(
                          onTap: () => _editField(context, state, fields[i][0]),
                          child: Container(
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
                              if (fields[i][0] != 'Age')
                                const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFC6CFD6)),
                            ],
                          ),
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

Future<void> _editField(BuildContext context, AppState state, String field) async {
  if (field == 'Age') return;

  if (field == 'Name') {
    final controller = TextEditingController(text: state.name);
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: GColors.white,
        title: Text('Name', style: GText.strong(GColors.ink).copyWith(fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GText.body(GColors.ink),
          decoration: const InputDecoration(hintText: 'Your first name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text('Cancel', style: GText.strong(GColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: Text('Save', style: GText.strong(GColors.blue)),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) state.set(() => state.name = value);
    return;
  }

  if (field == 'Birthday') {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.birthday,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) state.set(() => state.birthday = picked);
    return;
  }

  final options = field == 'Gender' ? ['Woman', 'Man', 'Other'] : ['Men', 'Women', 'Both'];
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: GColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            ListTile(
              minVerticalPadding: 14,
              title: Text(option, style: GText.strong(GColors.ink)),
              onTap: () => Navigator.pop(sheet, option),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  if (field == 'Gender') {
    state.set(() => state.gender = choice);
  } else {
    state.set(() => state.interestedIn = choice);
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
