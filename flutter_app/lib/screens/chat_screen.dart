import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/person.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/photo_circle.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scroll = ScrollController();

  AppState? _state;
  Person? person;
  List<ChatMessage> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  Future<void> _attach() async {
    final state = AppScope.of(context);
    _state = state;
    person = state.activePerson;
    state.api.addListener(_onApiChanged);
    if (person != null) state.api.markRead(person!.id);
    await _load();
  }

  Future<void> _load() async {
    final state = _state;
    if (state == null || person == null) {
      setState(() => loading = false);
      return;
    }
    final loaded = await state.api.messages(person!.id);
    if (!mounted) return;
    setState(() {
      messages = List.of(loaded);
      loading = false;
    });
    _toBottom();
  }

  /// Replies arrive on their own, so the thread has to follow the store.
  Future<void> _onApiChanged() async {
    final state = _state;
    if (state == null || person == null || !mounted) return;
    final loaded = await state.api.messages(person!.id);
    if (!mounted) return;
    setState(() => messages = List.of(loaded));
    _toBottom();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    final state = _state;
    if (text.isEmpty || state == null || person == null) return;
    controller.clear();
    await state.api.send(person!.id, text);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _state?.api.removeListener(_onApiChanged);
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final who = person;
    return Scaffold(
      backgroundColor: GColors.surface,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 16, 10),
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
                PhotoCircle(
                  diameter: 40,
                  ringWidth: 0,
                  shadow: false,
                  photoUrl: who?.photoUrl,
                  name: who?.name,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who?.name ?? 'Chat', style: GText.strong(GColors.ink).copyWith(fontSize: 16)),
                      if (who != null)
                        Text('still nearby - ' + who.distanceLabel,
                            style: GText.mono(GColors.green, size: 11), maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: GColors.blue))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text('MUTUAL GLANCE' + (who == null ? '' : ' - ' + who.city.toUpperCase()),
                                style: GText.mono(const Color(0xFFA3AEB8), size: 10)),
                          ),
                        );
                      }
                      final m = messages[i - 1];
                      return Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                          decoration: BoxDecoration(
                            color: m.mine ? GColors.blue : GColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(m.text, style: GText.body(m.mine ? GColors.white : GColors.ink)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: GColors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8EDF1))),
            ),
            padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.paddingOf(context).bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF0F3F6), borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: GText.body(GColors.ink),
                      decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                RoundIconButton(
                  tooltip: 'Send',
                  size: 46,
                  background: GColors.blue,
                  onTap: _send,
                  child: const Icon(Icons.arrow_upward_rounded, color: GColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
