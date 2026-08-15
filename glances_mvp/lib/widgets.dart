import 'package:flutter/material.dart';

import 'theme.dart';

/// The white curved "swoosh" that sits at the bottom of nearly every Glances
/// screen in the Figma.
class WaveBottom extends StatelessWidget {
  final Color color;
  final double height;
  const WaveBottom({super.key, this.color = Colors.white, this.height = 120});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WavePainter(color)),
      );
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.35, -size.height * 0.15, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.color != color;
}

/// Circular profile photo with the white ring used throughout the app.
class CirclePhoto extends StatelessWidget {
  final String? url;
  final double size;
  final String? fallbackLabel;
  final double ringWidth;

  const CirclePhoto({
    super.key,
    required this.url,
    this.size = 160,
    this.fallbackLabel,
    this.ringWidth = 5,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (fallbackLabel ?? '?').trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: ringWidth),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: (url == null || url!.isEmpty)
            ? _fallback(initial)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(initial),
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : Container(
                        color: GlancesColors.divider,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _fallback(String label) => Container(
        color: GlancesColors.accentLight,
        alignment: Alignment.center,
        child: Text(
          label.isEmpty ? '?' : label.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
}

/// Rounded pill button — the primary CTA style in the Figma.
class GlancesButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final Color textColor;
  final bool outlined;

  const GlancesButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color = GlancesColors.primary,
    this.textColor = Colors.white,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: outlined
            ? OutlinedButton(
                onPressed: loading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GlancesColors.border),
                  foregroundColor: GlancesColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlancesRadius.button),
                  ),
                ),
                child: _child(GlancesColors.textPrimary),
              )
            : FilledButton(
                onPressed: loading ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlancesRadius.button),
                  ),
                ),
                child: _child(textColor),
              ),
      );

  Widget _child(Color c) => loading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: c),
        )
      : Text(label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500));
}

/// Small pill used for "Pass both" / "Like both".
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PillButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text(label,
                style: const TextStyle(
                    color: GlancesColors.textPrimary, fontSize: 15)),
          ),
        ),
      );
}

/// Envelope / burger row with the orange unread badge.
class GlancesTopBar extends StatelessWidget {
  final VoidCallback? onMenu;
  final VoidCallback? onInbox;
  final int badge;
  final Widget? center;
  final Color iconColor;

  const GlancesTopBar({
    super.key,
    this.onMenu,
    this.onInbox,
    this.badge = 0,
    this.center,
    this.iconColor = GlancesColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: iconColor),
                onPressed: onMenu,
              ),
              Expanded(child: Center(child: center ?? const SizedBox())),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.mail_outline, color: iconColor),
                    onPressed: onInbox,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: GlancesColors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Full-screen empty / error state with an optional retry.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: GlancesColors.border),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: GlancesColors.textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: GlancesColors.textSecondary)),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                GlancesButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      );
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$error'),
      backgroundColor: GlancesColors.textPrimary,
      behavior: SnackBarBehavior.floating,
    ));
}
