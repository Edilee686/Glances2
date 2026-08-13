import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

/// Frame 11: photo, then Name / Location / Gender / Birthday / Height / About.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: GColors.white,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final me = state.me;
          if (me == null) return const SizedBox.shrink();
          final birthday = me.birthday;
          final fields = <List<String>>[
            ['Name', me.name],
            ['Location', me.city],
            ['Gender', me.gender],
            ['Interested in', me.seeking],
            [
              'Birthday',
              birthday == null
                  ? ''
                  : birthday.day.toString() +
                      ' ' +
                      _months[birthday.month - 1] +
                      ' ' +
                      birthday.year.toString()
            ],
            ['Height', me.heightCm == null ? '' : me.heightCm.toString() + ' cm'],
            ['About me', me.about],
          ];

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: fx(context, 30), vertical: fx(context, 20)),
                  child: Row(
                    children: [
                      FigChevron(color: GColors.grey, onTap: () => Navigator.maybePop(context)),
                      const Spacer(),
                      Text('Edit profile', style: GText.fig(context, 50, GColors.grey)),
                      const Spacer(),
                      SizedBox(width: fx(context, 100)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: fx(context, 60)),
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () => _photo(context, state),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              FigAvatar(
                                size: 460,
                                photoPath: me.photoPath,
                                name: me.name,
                                ringColor: GColors.white,
                                ringWidth: 14,
                                shadow: true,
                              ),
                              Container(
                                width: fx(context, 120),
                                height: fx(context, 120),
                                decoration: const BoxDecoration(
                                  color: GColors.cyan,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.photo_camera_rounded,
                                    color: GColors.white, size: fx(context, 60)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: fx(context, 60)),
                      for (final field in fields)
                        GestureDetector(
                          onTap: () => _edit(context, state, field[0]),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: fx(context, 34)),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: GColors.circle, width: 2)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: fx(context, 360),
                                  child: Text(field[0],
                                      style: GText.fig(context, 44, GColors.greyLine)),
                                ),
                                Expanded(
                                  child: Text(
                                    field[1].isEmpty ? 'Add' : field[1],
                                    style: GText.fig(
                                      context,
                                      44,
                                      field[1].isEmpty ? GColors.greyFaint : GColors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.edit_outlined,
                                    size: fx(context, 48), color: GColors.greyFaint),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: fx(context, 60)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _photo(BuildContext context, AppState state) async {
    final source = await showModalBottomSheet<ImageSource>(
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
              leading: Icon(Icons.photo_library_outlined,
                  color: GColors.cyan, size: fx(context, 64)),
              title: Text('Choose from library', style: GText.fig(context, 46, GColors.grey)),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: fx(context, 60), vertical: fx(context, 20)),
              leading: Icon(Icons.photo_camera_outlined,
                  color: GColors.cyan, size: fx(context, 64)),
              title: Text('Camera', style: GText.fig(context, 46, GColors.grey)),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1400, maxHeight: 1400, imageQuality: 88);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final name = 'photo_' + DateTime.now().millisecondsSinceEpoch.toString() + p.extension(picked.path);
    final saved = await File(picked.path).copy(p.join(dir.path, name));
    await state.updateMe({'photo_path': saved.path});
  }

  Future<void> _edit(BuildContext context, AppState state, String field) async {
    if (field == 'Birthday') {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: state.me?.birthday ?? DateTime(now.year - 25),
        firstDate: DateTime(1940),
        lastDate: DateTime(now.year - 18, now.month, now.day),
      );
      if (picked != null) await state.updateMe({'birthday': picked.millisecondsSinceEpoch});
      return;
    }

    if (field == 'Gender' || field == 'Interested in') {
      final options = field == 'Gender'
          ? const ['Woman', 'Man', 'Other']
          : const ['Women', 'Men', 'Everyone'];
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: GColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(fx(context, 60))),
        ),
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: fx(context, 60), vertical: fx(context, 16)),
                  title: Text(option, style: GText.fig(context, 46, GColors.grey)),
                  onTap: () => Navigator.pop(sheet, option),
                ),
            ],
          ),
        ),
      );
      if (choice == null) return;
      final column = field == 'Gender' ? 'gender' : 'seeking';
      await state.updateMe({column: choice});
      return;
    }

    final me = state.me;
    final initial = switch (field) {
      'Name' => me?.name ?? '',
      'Location' => me?.city ?? '',
      'Height' => me?.heightCm?.toString() ?? '',
      _ => me?.about ?? '',
    };
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: GColors.white,
        title: Text(field, style: GText.fig(context, 50, GColors.grey)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: field == 'About me' ? 4 : 1,
          keyboardType: field == 'Height' ? TextInputType.number : TextInputType.text,
          style: GText.fig(context, 44, GColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text('Cancel', style: GText.fig(context, 42, GColors.greyLine)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: Text('Save', style: GText.fig(context, 42, GColors.cyan)),
          ),
        ],
      ),
    );
    if (value == null) return;
    if (field == 'Name') {
      await state.updateMe({'name': value});
    } else if (field == 'Location') {
      await state.updateMe({'city': value});
    } else if (field == 'Height') {
      await state.updateMe({'height_cm': int.tryParse(value)});
    } else {
      await state.updateMe({'about': value});
    }
  }
}
