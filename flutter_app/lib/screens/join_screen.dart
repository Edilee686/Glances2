import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';
import '../widgets/heart.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  static const _slides = [
    'See each other in the reality',
    'Send a Like, dont miss it.',
    'Get a Like and start a chat..',
    'Every chat leads to a date.',
  ];

  final _pages = PageController();
  int _slide = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _social(AuthProvider provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppScope.of(context);
    final result = await state.auth.signInWith(provider);
    await state.boot();
    if (!mounted) return;
    setState(() => _busy = false);
    final me = state.me;
    Navigator.pushReplacementNamed(
      context,
      result.isNew || me == null || !me.onboarded ? Routes.name : Routes.sight,
    );
  }

  Future<void> _phone() async {
    final controller = TextEditingController(text: '+972');
    final number = await showDialog<String>(
      context: context,
      barrierColor: GColors.scrim.withValues(alpha: 0.7),
      builder: (dialog) => _PhoneDialog(controller: controller),
    );
    if (number == null || number.trim().length < 7 || !mounted) return;
    final state = AppScope.of(context);
    state.auth.requestCode(number.trim());
    if (!mounted) return;
    Navigator.pushNamed(context, Routes.verify);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.white,
      body: Stack(
        children: [
          // Cyan curved panel: Figma 1080x1475 with the bottom bow.
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            width: double.infinity,
            child: const CurvedSheet(color: GColors.cyan, bulge: 0.145),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: fx(context, 30), top: fx(context, 30)),
                  child: const Align(alignment: Alignment.centerLeft, child: FigWordmark()),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _slide = i),
                    itemBuilder: (context, i) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TwoTonedHeart(size: fx(context, 420), solid: GColors.white.withValues(alpha: 0.9)),
                        SizedBox(height: fx(context, 110)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: fx(context, 80)),
                          child: Text(
                            _slides[i],
                            textAlign: TextAlign.center,
                            style: GText.fig(context, 50, GColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      Container(
                        width: fx(context, 24),
                        height: fx(context, 24),
                        margin: EdgeInsets.symmetric(horizontal: fx(context, 12)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _slide ? GColors.white : GColors.white.withValues(alpha: 0.45),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: fx(context, 120)),
                FigButton(
                  label: 'Sign in with Facebook',
                  background: GColors.white,
                  foreground: GColors.facebook,
                  onTap: _busy ? null : () => _social(AuthProvider.facebook),
                  leading: Icon(Icons.facebook, color: GColors.facebook, size: fx(context, 72)),
                ),
                SizedBox(height: fx(context, 40)),
                FigButton(
                  label: 'Join with Gmail',
                  background: GColors.cyan,
                  onTap: _busy ? null : () => _social(AuthProvider.google),
                  leading: Container(
                    width: fx(context, 64),
                    height: fx(context, 64),
                    decoration: const BoxDecoration(color: GColors.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: GText.fig(context, 44, GColors.cyan, weight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(height: fx(context, 30)),
                GestureDetector(
                  onTap: _busy ? null : _phone,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: fx(context, 16)),
                    child: Text(
                      'Continue with phone number',
                      style: GText.fig(context, 40, GColors.grey),
                    ),
                  ),
                ),
                Text(
                  'Terms and Conditions, Privacy Policy',
                  style: GText.fig(context, 36, GColors.skyLight),
                ),
                SizedBox(height: fx(context, 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma Frame 43 modal: "Continue with", phone field, Cancel / Accept.
class _PhoneDialog extends StatelessWidget {
  const _PhoneDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: fx(context, 854),
        decoration: BoxDecoration(
          color: GColors.white,
          borderRadius: BorderRadius.circular(fx(context, 40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: fx(context, 79)),
            Text('Continue with', style: GText.fig(context, 50, GColors.grey)),
            SizedBox(height: fx(context, 40)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fx(context, 115)),
              child: Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: fx(context, 98), color: const Color(0xFF969696)),
                  SizedBox(width: fx(context, 18)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      style: GText.fig(context, 50, GColors.grey),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '+972-0508508443',
                        hintStyle: GText.fig(context, 50, GColors.greyDim),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: fx(context, 40)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fx(context, 99)),
              child: Text(
                'We will send you a one time sms message verification, carrier rates may apply.',
                textAlign: TextAlign.center,
                style: GText.fig(context, 36, GColors.greyDim, height: 1.3),
              ),
            ),
            SizedBox(height: fx(context, 60)),
            Container(height: fx(context, 3), color: const Color(0xFFC4C4C4)),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DialogAction(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Container(width: fx(context, 2), color: const Color(0xFFC4C4C4)),
                  Expanded(
                    child: _DialogAction(
                      label: 'Accept',
                      onTap: () => Navigator.pop(context, controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fx(context, 50)),
        child: Center(
          child: Text(label, style: GText.fig(context, 50, GColors.cyan)),
        ),
      ),
    );
  }
}
