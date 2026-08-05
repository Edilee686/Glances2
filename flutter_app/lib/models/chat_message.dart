class ChatMessage {
  const ChatMessage({required this.text, required this.mine, required this.sentAt});
  final String text;
  final bool mine;
  final DateTime sentAt;
}
