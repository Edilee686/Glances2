import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/fig.dart';
import '../../widgets/onboarding_shell.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  String? _path;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _path = AppScope.read(context).me?.photoPath;
  }

  /// Copy the picked file into the app's documents directory so it survives
  /// the OS clearing its temp cache.
  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 88,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final name = 'photo_' + DateTime.now().millisecondsSinceEpoch.toString() + p.extension(picked.path);
      final saved = await File(picked.path).copy(p.join(dir.path, name));
      if (!mounted) return;
      setState(() => _path = saved.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return OnboardingShell(
      prompt: 'Please add a clear photo of your face',
      subhead: 'You are almost done..!',
      step: 5,
      onContinue: _path == null
          ? null
          : () async {
              await state.updateMe({'photo_path': _path, 'onboarded': 1});
              await state.refresh();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, Routes.sight, (route) => false);
            },
      child: Column(
        children: [
          FigAvatar(
            size: 560,
            photoPath: _path,
            ringColor: GColors.white.withValues(alpha: 0.25),
            ringWidth: 24,
          ),
          SizedBox(height: fx(context, 70)),
          FigButton(
            label: 'Choose from library',
            background: GColors.white,
            foreground: GColors.cyan,
            onTap: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          SizedBox(height: fx(context, 36)),
          FigButton(
            label: 'Camera',
            background: GColors.white.withValues(alpha: 0.25),
            foreground: GColors.white,
            onTap: _busy ? null : () => _pick(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}
