import 'package:flutter/material.dart';

import '../models/chat_message.dart';
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
  List<ChatMessage> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = AppScope.of(context);
    final loaded = await state.api.messages(state.current.id);
    if (!mounted) return;
    setState(() {
      messages = List.of(loaded);
      loading = false;
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final state = AppScope.of(context);
    controller.clear();
    await state.api.send(state.current.id, text);
    if (!mounted) return;
    setState(() => messages.add(ChatMessage(text: text, mine: true, sentAt: DateTime.now())));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (scroll.hasClients) {
      scroll.animateTo(scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final person = state.current;
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
                PhotoCircle(diameter: 40, ringWidth: 0, shadow: false, photoUrl: person.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.name, style: GText.strong(GColors.ink).copyWith(fontSize: 16)),
                      Text('still nearby - ' + person.distanceLabel,
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
                            child: Text('MUTUAL GLANCE - ' + person.city.toUpperCase(),
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
