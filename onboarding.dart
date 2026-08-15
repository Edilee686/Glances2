import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

/// Gender → date of birth (18+) → who you want to meet → photo.
///
/// The backend refuses discovery until a profile row, a settings row and at
/// least one photo exist (user_validate_profile / user_validate_setting, and
/// an empty feed without a photo), so all four steps are mandatory.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _step = 0;
  bool _busy = false;

  String? _gender;
  DateTime? _dob;
  String _meetGender = 'both';
  RangeValues _ageRange = const RangeValues(18, 45);
  File? _photo;

  void _next() {
    setState(() => _step++);
    _controller.animateToPage(_step,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _finish() async {
    if (_photo == null) {
      showError(context, 'Please add a clear photo of your face');
      return;
    }
    setState(() => _busy = true);
    try {
      final me = Session.instance.me!;

      await Api.instance.saveProfile(
        dateOfBirth: _dob!,
        gender: _gender!,
        existingId: me.profile?.id,
      );

      final existing = me.settings ?? Settings();
      await Api.instance.saveSettings(existing.copyWith(
        meetGender: _meetGender,
        preferredAgeFrom: _ageRange.start.round(),
        preferredAgeTo: _ageRange.end.round(),
      ));

      // The server runs an OpenCV face check and returns
      // 400 "Sorry, face not found" if it can't see one.
      await Api.instance.uploadPhoto(_photo!);

      await Session.instance.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlancesColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _step ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _genderStep(),
                  _birthdayStep(),
                  _preferenceStep(),
                  _photoStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child, required Widget cta}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: child)),
                  SizedBox(width: double.infinity, child: cta),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _choice(String label, String value, String? group, ValueChanged<String> onTap) {
    final selected = group == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: GlancesButton(
          label: label,
          outlined: !selected,
          color: GlancesColors.primary,
          onPressed: () => onTap(value),
        ),
      ),
    );
  }

  Widget _genderStep() => _card(
        title: 'What is your gender?',
        child: Column(
          children: [
            _choice('Woman', 'woman', _gender, (v) => setState(() => _gender = v)),
            _choice('Man', 'man', _gender, (v) => setState(() => _gender = v)),
            _choice('Other', 'others', _gender, (v) => setState(() => _gender = v)),
          ],
        ),
        cta: GlancesButton(
          label: 'Continue',
          onPressed: _gender == null ? null : _next,
        ),
      );

  Widget _birthdayStep() {
    final ok = _dob != null && _ageOf(_dob!) >= 18;
    return _card(
      title: 'What is your date of birth?',
      child: Column(
        children: [
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
                firstDate: DateTime(now.year - 100),
                lastDate: DateTime(now.year - 18, now.month, now.day),
                helpText: 'Your date of birth',
              );
              if (picked != null) setState(() => _dob = picked);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlancesRadius.button)),
            ),
            child: Text(
              _dob == null
                  ? 'Choose your date of birth'
                  : '${_dob!.day}/${_dob!.month}/${_dob!.year}   ·   ${_ageOf(_dob!)} years old',
              style: const TextStyle(
                  fontSize: 16, color: GlancesColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You must be at least 18 years old to join Glances',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: GlancesColors.textSecondary),
          ),
        ],
      ),
      cta: GlancesButton(label: 'Continue', onPressed: ok ? _next : null),
    );
  }

  Widget _preferenceStep() => _card(
        title: 'Who would you like to meet?',
        child: Column(
          children: [
            _choice('Women', 'woman', _meetGender,
                (v) => setState(() => _meetGender = v)),
            _choice('Men', 'man', _meetGender,
                (v) => setState(() => _meetGender = v)),
            _choice('Both', 'both', _meetGender,
                (v) => setState(() => _meetGender = v)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Age  ${_ageRange.start.round()} – ${_ageRange.end.round()}',
                style: const TextStyle(color: GlancesColors.textSecondary),
              ),
            ),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 80,
              divisions: 62,
              activeColor: GlancesColors.primary,
              labels: RangeLabels('${_ageRange.start.round()}',
                  '${_ageRange.end.round()}'),
              onChanged: (v) => setState(() => _ageRange = v),
            ),
          ],
        ),
        cta: GlancesButton(label: 'Continue', onPressed: _next),
      );

  Widget _photoStep() => _card(
        title: 'Please add a clear photo of your face',
        child: Column(
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 84,
              backgroundColor: GlancesColors.divider,
              backgroundImage: _photo == null ? null : FileImage(_photo!),
              child: _photo == null
                  ? const Icon(Icons.person,
                      size: 72, color: GlancesColors.border)
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GlancesButton(
                label: 'Choose from library',
                outlined: true,
                onPressed: () => _pickPhoto(ImageSource.gallery),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: GlancesButton(
                label: 'Camera',
                outlined: true,
                onPressed: () => _pickPhoto(ImageSource.camera),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Glances checks that a face is visible. Photos without a '
              'detectable face are rejected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: GlancesColors.textSecondary),
            ),
          ],
        ),
        cta: GlancesButton(
          label: "You're almost done!",
          loading: _busy,
          onPressed: _photo == null ? null : _finish,
        ),
      );

  int _ageOf(DateTime dob) {
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) a--;
    return a;
  }
}
