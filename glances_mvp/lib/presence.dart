import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';
import 'config.dart';

/// Keeps the user marked "online" on the server.
///
/// This is not cosmetic. custom_auth.User.status is written by exactly one
/// place in the backend — chats.consumer.ServiceConsumer, on WebSocket connect:
///
///     async def connect(self):
///         self.user_id = self.scope['url_route']['kwargs']['pk']
///         await self.set_status(self.user_id)     # User.status = True
///
/// and discovery filters on it:
///
///     if not from_bts and user.setting.online:
///         filtered_users = filtered_users.filter(status=True)
///
/// UserSetting.online defaults to True, so a client that never opens this
/// socket sees an empty discovery feed forever — everyone is filtered out for
/// being "offline". Disconnecting sets status back to False.
class Presence {
  Presence._();
  static final Presence instance = Presence._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retry;
  int? _userId;
  bool _wanted = false;

  bool get connected => _channel != null;

  void connect(int userId) {
    _userId = userId;
    _wanted = true;
    _open();
  }

  void disconnect() {
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _open() {
    if (!_wanted || _userId == null) return;

    final token = Api.instance.token ?? '';
    final url = '${Config.wsUrl}/ws/user-status/$_userId?token=$token';

    try {
      final ch = WebSocketChannel.connect(Uri.parse(url));
      _channel = ch;
      _sub = ch.stream.listen(
        (_) {},                       // server sends nothing on this channel
        onError: (_) => _scheduleRetry(),
        onDone: _scheduleRetry,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleRetry();
    }
  }

  /// The socket drops whenever the phone sleeps or the network flaps, and a
  /// dropped socket means the server marks you offline and you vanish from
  /// everyone's feed. Reconnect on a modest delay.
  void _scheduleRetry() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_wanted) return;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 5), _open);
  }
}
