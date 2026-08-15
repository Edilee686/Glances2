import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

/// Chat with the Glances expiry window.
///
/// The room only starts its countdown once the partner has replied
/// (chats.services.chat_room.set_live_time). Before that live_time_to is null
/// and the conversation doesn't expire. Once it's ticking you get 10 minutes,
/// extendable via POST /api/chats/extend-time/.
class ChatScreen extends StatefulWidget {
  final int chatId;
  const ChatScreen({super.key, required this.chatId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  ChatRoom? _room;
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  Timer? _ticker;

  int get _myId => Session.instance.me?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _room?.liveTimeTo != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.sink.close();
    _ticker?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final room = await Api.instance.chat(widget.chatId);
      final msgs = await Api.instance.messages(widget.chatId);
      if (!mounted) return;
      setState(() {
        _room = room;
        // Server returns newest-first; we render oldest-first.
        _messages = msgs.reversed.toList();
        _loading = false;
      });
      _connectSocket();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _connectSocket() {
    // The token is appended for the patched server, which authenticates the
    // socket from the query string. The current unpatched server ignores it
    // harmlessly, so this works against both.
    final token = Api.instance.token ?? '';
    final url = '${Config.wsUrl}/ws/chat/${widget.chatId}?token=$token';
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _wsSub = _ws!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            if (data['type'] != 'chat_message') return;
            final senderId = data['user_id'];
            // Our own sends are appended optimistically already.
            if (senderId == _myId) return;
            setState(() {
              _messages.add(Message(
                id: DateTime.now().millisecondsSinceEpoch,
                body: (data['message'] ?? '') as String,
                owner: _room?.partner(_myId),
                created: DateTime.now(),
              ));
            });
            _scrollToEnd();
            _refreshRoom();
          } catch (_) {/* ignore malformed frames */}
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {
      // Socket is an optimisation — REST still works without it.
    }
  }

  Future<void> _refreshRoom() async {
    try {
      final room = await Api.instance.chat(widget.chatId);
      if (mounted) setState(() => _room = room);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _input.clear();

    try {
      final msg = await Api.instance.sendMessage(widget.chatId, text);
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToEnd();

      // Mirror to the socket so the other side sees it immediately.
      _ws?.sink.add(jsonEncode({
        'type': 'chat_message',
        'message': text,
        'user_id': _myId,
      }));

      await _refreshRoom();
    } catch (e) {
      if (mounted) {
        showError(context, e);
        _input.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _extend() async {
    try {
      await Api.instance.extendChat(widget.chatId);
      await _refreshRoom();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final partner = _room?.partner(_myId);
    final remaining = _room?.remaining;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(partner?.name ?? 'Chat',
                style: const TextStyle(fontSize: 17)),
            if (partner != null)
              Text(
                partner.online ? 'online' : 'offline',
                style: const TextStyle(
                    fontSize: 11, color: GlancesColors.textSecondary),
              ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Could not open this chat',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : Column(
                  children: [
                    if (remaining != null) _timerBar(remaining),
                    Expanded(
                      child: _messages.isEmpty
                          ? const EmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: 'Say something',
                              subtitle:
                                  'The countdown only starts once they reply.',
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) => _bubble(_messages[i]),
                            ),
                    ),
                    _composer(remaining),
                  ],
                ),
    );
  }

  Widget _timerBar(Duration remaining) {
    final expired = remaining == Duration.zero;
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    return Container(
      width: double.infinity,
      color: expired
          ? GlancesColors.divider
          : GlancesColors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(expired ? Icons.timer_off : Icons.timer,
              size: 18,
              color: expired
                  ? GlancesColors.textSecondary
                  : GlancesColors.primary),
          const SizedBox(width: 8),
          Text(
            expired
                ? 'The chat time is over'
                : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} left',
            style: TextStyle(
              color: expired
                  ? GlancesColors.textSecondary
                  : GlancesColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _extend,
            child: const Text('+10 min'),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Message m) {
    final mine = m.owner?.id == _myId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? GlancesColors.primary : GlancesColors.divider,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 2),
            bottomRight: Radius.circular(mine ? 2 : 16),
          ),
        ),
        child: Text(
          m.body,
          style: TextStyle(
              color: mine ? Colors.white : GlancesColors.textPrimary),
        ),
      ),
    );
  }

  Widget _composer(Duration? remaining) {
    final blocked = _room?.locked == true || remaining == Duration.zero;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: blocked
            ? Row(
                children: [
                  const Expanded(
                    child: Text(
                      'This chat is closed. Extend it to keep talking.',
                      style: TextStyle(color: GlancesColors.textSecondary),
                    ),
                  ),
                  TextButton(onPressed: _extend, child: const Text('Extend')),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                        backgroundColor: GlancesColors.primary),
                  ),
                ],
              ),
      ),
    );
  }
}
