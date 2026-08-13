import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fig.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(markRead: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool markRead = false}) async {
    final state = AppScope.of(context);
    final me = state.me;
    final other = state.active;
    if (me == null || other == null) {
      setState(() => _loading = false);
      return;
    }
    if (markRead) await state.markRead(other.id);
    final loaded = await state.db.messages(me.id, other.id);
    if (!mounted) return;
    setState(() {
      _messages = loaded;
      _loading = false;
    });
    _toBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final state = AppScope.of(context);
    final other = state.active;
    if (other == null) return;
    _controller.clear();
    await state.send(other.id, text);
    await _load();
    // The reply lands a beat later; pick it up when it does.
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) _load();
    });
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me;
    final other = state.active;

    return Scaffold(
      backgroundColor: GColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: fx(context, 30), vertical: fx(context, 20)),
              child: Row(
                children: [
                  FigChevron(
                    color: GColors.grey,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(other?.name ?? '', style: GText.fig(context, 44, GColors.grey)),
                      Text(
                        'Last seen ' + (other?.seenLabel ?? ''),
                        style: GText.fig(context, 30, GColors.greyLine),
                      ),
                    ],
                  ),
                  SizedBox(width: fx(context, 24)),
                  FigAvatar(
                    size: 130,
                    photoPath: other?.photoPath,
                    name: other?.name,
                    ringColor: GColors.white,
                    ringWidth: 6,
                    shadow: true,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: GColors.cyan))
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                          fx(context, 48), fx(context, 24), fx(context, 48), fx(context, 24)),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = m.authorId == me?.id;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                            ),
                            margin: EdgeInsets.only(bottom: fx(context, 28)),
                            padding: EdgeInsets.symmetric(
                                horizontal: fx(context, 44), vertical: fx(context, 28)),
                            decoration: BoxDecoration(
                              color: mine ? GColors.cyan : GColors.circle,
                              borderRadius: BorderRadius.circular(fx(context, 50)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.body,
                                  style: GText.fig(
                                    context,
                                    40,
                                    mine ? GColors.white : GColors.grey,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: fx(context, 6)),
                                Text(
                                  m.timeLabel,
                                  style: GText.fig(
                                    context,
                                    26,
                                    mine
                                        ? GColors.white.withValues(alpha: 0.8)
                                        : GColors.greyLine,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(height: fx(context, 2), color: GColors.greyLine),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  fx(context, 75), fx(context, 24), fx(context, 48), fx(context, 30)),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: fx(context, 120),
                      padding: EdgeInsets.symmetric(horizontal: fx(context, 38)),
                      decoration: BoxDecoration(
                        color: GColors.white,
                        borderRadius: BorderRadius.circular(fx(context, 60)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(fx(context, 4), fx(context, 8)),
                            blurRadius: fx(context, 16),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GText.fig(context, 40, GColors.grey),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Write a message',
                          hintStyle: GText.fig(context, 40, GColors.greyFaint),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: fx(context, 30)),
                  GestureDetector(
                    onTap: _send,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(fx(context, 16)),
                      child: Icon(Icons.send_rounded,
                          color: GColors.cyan, size: fx(context, 80)),
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
