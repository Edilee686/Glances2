import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat.dart';
import 'inbox.dart';
import 'settings.dart';

/// The Glances screen: people you have physically crossed paths with recently.
///
/// Candidates come from GET /api/users/filtered-list/, which the server builds
/// from your last uploaded coordinate plus your gender / age / distance
/// preferences. Two are shown at a time — the "choose one profile every swipe"
/// mechanic from the Figma — with Pass both / Like both, per-card like, and undo.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<Candidate> _queue = [];
  final List<Candidate> _passed = [];
  bool _loading = true;
  String? _error;
  bool _advanced = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // The backend only counts encounters from the last 10 minutes (2 in dev
    // mode), so the feed goes stale quickly. Re-poll while the screen is open.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      // 'geo' = GPS + wifi. 'bts' = bluetooth. 'all' = everything.
      // GPS is the only signal that works cross-platform today, so we use it.
      final list = await Api.instance.discover(filter: 'geo');
      if (!mounted) return;
      setState(() {
        final seen = _passed.map((c) => c.id).toSet();
        _queue = list.where((c) => !seen.contains(c.id)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _like(Candidate c) async {
    try {
      final like = await Api.instance.like(c.id);
      if (!mounted) return;
      setState(() => _queue.removeWhere((x) => x.id == c.id));
      if (like.isMutual) {
        _showMatch(c, like.chatId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You liked ${c.name ?? 'them'} — they will only know '
                'if they like you back'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await Session.instance.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _pass(Candidate c) {
    setState(() {
      _passed.add(c);
      _queue.removeWhere((x) => x.id == c.id);
    });
  }

  void _undo() {
    if (_passed.isEmpty) return;
    setState(() => _queue.insert(0, _passed.removeLast()));
  }

  void _showMatch(Candidate c, int? chatId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 64, color: GlancesColors.orange),
              const SizedBox(height: 12),
              const Text("It's a match!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You and ${c.name ?? 'they'} liked each other',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GlancesColors.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GlancesButton(
                  label: 'Send a message',
                  onPressed: () {
                    Navigator.pop(context);
                    if (chatId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chatId)),
                      );
                    }
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later',
                    style: TextStyle(color: GlancesColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = Session.instance.me?.profile?.unreadMessages ?? 0;

    return Scaffold(
      backgroundColor: _advanced ? Colors.white : GlancesColors.surfaceTint,
      body: Column(
        children: [
          GlancesTopBar(
            iconColor: _advanced ? GlancesColors.textPrimary : Colors.white,
            badge: unread,
            onMenu: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            onInbox: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const InboxScreen())),
            center: _ModeToggle(
              advanced: _advanced,
              onChanged: (v) => setState(() => _advanced = v),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not reach Glances',
        subtitle: _error,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    final locationProblem = Session.instance.locationStatus;
    if (locationProblem != null) {
      return EmptyState(
        icon: Icons.location_off,
        title: 'Location needed',
        subtitle: '$locationProblem\n\nGlances finds people you were '
            'physically near, so it needs your position.',
        actionLabel: 'Retry',
        onAction: () async {
          await Session.instance.pushLocationNow();
          _load();
        },
      );
    }

    if (_queue.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'Nobody around just yet',
        subtitle: 'Glances only shows people you have actually crossed paths '
            'with in the last few minutes. Move around, and check back.',
        actionLabel: 'Refresh',
        onAction: _load,
      );
    }

    return _advanced ? _twoUp() : _stack();
  }

  /// Simple mode — one focused profile with the next peeking behind.
  Widget _stack() {
    final first = _queue.first;
    final second = _queue.length > 1 ? _queue[1] : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (second != null)
          Positioned(
            top: 24,
            child: Opacity(
              opacity: 0.55,
              child: CirclePhoto(
                  url: second.imageUrl, size: 150, fallbackLabel: second.name),
            ),
          ),
        Center(
          child: GestureDetector(
            onTap: () => _openProfile(first),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CirclePhoto(
                    url: first.imageUrl, size: 230, fallbackLabel: first.name),
                const SizedBox(height: 16),
                Text(
                  first.name ?? '',
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                if (first.likedEarlyMe)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Already likes you',
                        style: TextStyle(color: Colors.white70)),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundAction(
                      icon: Icons.close,
                      onTap: () => _pass(first),
                    ),
                    const SizedBox(width: 32),
                    _RoundAction(
                      icon: Icons.favorite,
                      color: GlancesColors.orange,
                      onTap: () => _like(first),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: const WaveBottom()),
      ],
    );
  }

  /// Advanced mode — the Figma's "choose one profile every swipe".
  Widget _twoUp() {
    final a = _queue.first;
    final b = _queue.length > 1 ? _queue[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Expanded(child: _twoUpCard(a)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.replay,
                    color: _passed.isEmpty
                        ? GlancesColors.border
                        : GlancesColors.textSecondary),
                onPressed: _passed.isEmpty ? null : _undo,
              ),
              PillButton(
                label: 'Pass both',
                onPressed: () {
                  _pass(a);
                  if (b != null) _pass(b);
                },
              ),
              PillButton(
                label: 'Like both',
                onPressed: () async {
                  await _like(a);
                  if (b != null) await _like(b);
                },
              ),
            ],
          ),
          Expanded(
            child: b == null
                ? const Center(
                    child: Text('Only one person nearby right now',
                        style: TextStyle(color: GlancesColors.textSecondary)))
                : _twoUpCard(b),
          ),
        ],
      ),
    );
  }

  Widget _twoUpCard(Candidate c) => GestureDetector(
        onTap: () => _openProfile(c),
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 250) _like(c);
          if (v < -250) _pass(c);
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CirclePhoto(url: c.imageUrl, size: 165, fallbackLabel: c.name),
              const SizedBox(height: 10),
              Text(c.name ?? '',
                  style: const TextStyle(
                      fontSize: 16, color: GlancesColors.textPrimary)),
              if (c.likedEarlyMe)
                const Text('likes you',
                    style: TextStyle(
                        fontSize: 12, color: GlancesColors.orange)),
            ],
          ),
        ),
      );

  Future<void> _openProfile(Candidate c) async {
    try {
      final data = await Api.instance.user(c.id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _ProfileSheet(
          data: data,
          onLike: () {
            Navigator.pop(context);
            _like(c);
          },
          onPass: () {
            Navigator.pop(context);
            _pass(c);
          },
          onBlock: () async {
            Navigator.pop(context);
            await Api.instance.ban(c.id);
            _pass(c);
          },
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}

class _ModeToggle extends StatelessWidget {
  final bool advanced;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.advanced, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!advanced),
        child: Container(
          width: 64,
          height: 30,
          decoration: BoxDecoration(
            color: advanced ? GlancesColors.divider : Colors.white24,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white54),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment:
                advanced ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: advanced ? GlancesColors.textSecondary : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                advanced ? Icons.people : Icons.person,
                size: 15,
                color: advanced ? Colors.white : GlancesColors.primary,
              ),
            ),
          ),
        ),
      );
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.color = GlancesColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      );
}

class _ProfileSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onBlock;

  const _ProfileSheet({
    required this.data,
    required this.onLike,
    required this.onPass,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final images = ((data['images'] as List?) ?? [])
        .map((e) => (e as Map)['image_url'] as String?)
        .whereType<String>()
        .toList();
    final name = data['name'] as String? ?? '';
    final age = data['age'];
    final city = data['city'] as String?;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CirclePhoto(
            url: images.isEmpty ? null : images.first,
            size: 180,
            fallbackLabel: name,
          ),
          const SizedBox(height: 16),
          Text(
            [name, if (age != null) '$age'].join(', '),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          if (city != null && city.isNotEmpty)
            Text(city,
                style: const TextStyle(color: GlancesColors.textSecondary)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GlancesButton(
                    label: 'Pass', outlined: true, onPressed: onPass),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlancesButton(
                    label: 'Like',
                    color: GlancesColors.orange,
                    onPressed: onLike),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onBlock,
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Block this person'),
            style: TextButton.styleFrom(
                foregroundColor: GlancesColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
