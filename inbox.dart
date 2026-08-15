import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat.dart';

/// The unified "likes and messages" list from the Figma — conversations and
/// pending likes in one feed, each row saying what to do next.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<ChatRoom> _chats = [];
  List<Like> _sent = [];
  List<Like> _received = [];
  bool _loading = true;
  String? _error;

  int get _myId => Session.instance.me?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final chats = await Api.instance.chats();
      final likes = await Api.instance.likes();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _sent = likes.sent.where((l) => !l.isMutual).toList();
        _received = likes.received.where((l) => !l.isMutual).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes and messages'),
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Could not load',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list(),
                ),
    );
  }

  Widget _list() {
    final rows = <Widget>[];

    for (final c in _chats) {
      final p = c.partner(_myId);
      rows.add(_row(
        name: p?.name ?? 'Someone',
        imageUrl: p?.imageUrl,
        subtitle: c.lastMessage ??
            (c.unread > 0 ? "You've got a message :)" : 'Send them a message :)'),
        heart: GlancesColors.orange,
        envelope: c.unread > 0 ? GlancesColors.primary : GlancesColors.border,
        badge: c.unread,
        trailing: c.remaining != null && c.remaining != Duration.zero
            ? '${c.remaining!.inMinutes}m'
            : (c.locked ? 'closed' : null),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(chatId: c.id)));
          _load();
        },
      ));
    }

    for (final l in _received) {
      final u = l.sender;
      rows.add(_row(
        name: u?.name ?? 'Someone',
        imageUrl: u?.imageUrl,
        subtitle: 'Likes you — like them back to start talking',
        heart: GlancesColors.orange,
        envelope: GlancesColors.border,
        onTap: () async {
          try {
            final like = await Api.instance.like(u!.id);
            if (!mounted) return;
            if (like.isMutual && like.chatId != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: like.chatId!)),
              );
            }
            _load();
          } catch (e) {
            if (mounted) showError(context, e);
          }
        },
      ));
    }

    for (final l in _sent) {
      final u = l.receiver;
      rows.add(_row(
        name: u?.name ?? 'Someone',
        imageUrl: u?.imageUrl,
        subtitle: 'You like them :)  ·  waiting for a mutual like',
        heart: GlancesColors.border,
        envelope: GlancesColors.border,
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Remove this like?'),
              content: Text('${u?.name ?? 'They'} will not be told either way.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove')),
              ],
            ),
          );
          if (ok == true) {
            try {
              await Api.instance.unlike(l.id);
              _load();
            } catch (e) {
              if (mounted) showError(context, e);
            }
          }
        },
      ));
    }

    if (rows.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.favorite_border,
            title: 'Nothing here yet',
            subtitle:
                'Likes and conversations will appear here once you start '
                'glancing at people nearby.',
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _row({
    required String name,
    required String? imageUrl,
    required String subtitle,
    required Color heart,
    required Color envelope,
    int badge = 0,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: SizedBox(
        width: 56,
        child: Row(
          children: [
            Icon(Icons.mail, size: 20, color: envelope),
            const SizedBox(width: 6),
            Icon(Icons.favorite, size: 20, color: heart),
          ],
        ),
      ),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: GlancesColors.textPrimary)),
      subtitle: Text(subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 11, color: GlancesColors.textSecondary)),
          const SizedBox(width: 8),
          CirclePhoto(
              url: imageUrl, size: 48, fallbackLabel: name, ringWidth: 2),
        ],
      ),
    );
  }
}
