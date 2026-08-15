import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

/// Thin client over the existing Django REST API. Every path here was read off
/// the server's urls.py — nothing is invented.
class Api {
  Api._();
  static final Api instance = Api._();

  String? _token;
  String? get token => _token;
  set token(String? t) => _token = t;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${Config.apiUrl}$path').replace(queryParameters: query);

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiException(r.statusCode, _errorText(body, r.statusCode));
  }

  String _errorText(dynamic body, int status) {
    if (body is Map) {
      for (final k in ['detail', 'message', 'error', 'non_field_errors']) {
        final v = body[k];
        if (v is String) return v;
        if (v is List && v.isNotEmpty) return '${v.first}';
      }
      // DRF field errors: {"email": ["Email already exists"]}
      final parts = <String>[];
      body.forEach((k, v) {
        if (v is List && v.isNotEmpty) parts.add('$k: ${v.first}');
        else if (v is String) parts.add('$k: $v');
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (body is List && body.isNotEmpty) return '${body.first}';
    return 'Request failed ($status)';
  }

  Future<dynamic> _get(String p, [Map<String, String>? q]) async =>
      _decode(await http.get(_u(p, q), headers: _headers)
          .timeout(const Duration(seconds: 20)));

  Future<dynamic> _post(String p, Object? body) async =>
      _decode(await http
          .post(_u(p), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20)));

  Future<dynamic> _patch(String p, Object? body) async =>
      _decode(await http
          .patch(_u(p), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20)));

  Future<dynamic> _delete(String p) async =>
      _decode(await http.delete(_u(p), headers: _headers)
          .timeout(const Duration(seconds: 20)));

  // ── auth ───────────────────────────────────────────────────────────────────

  /// POST /api/users/login/  (rest_framework_jwt obtain_jwt_token)
  /// USERNAME_FIELD is 'email', so the credential field is 'email'.
  /// Response shape comes from glances_app.utils.jwt_response_payload_handler:
  ///   { "type": "Bearer", "token": "...", "user": {...} }
  Future<Me> login(String email, String password) async {
    final r = await _post('/users/login/', {
      'email': email.trim(),
      'password': password,
    });
    _token = r['token'] as String;
    return Me.fromJson(Map<String, dynamic>.from(r['user'] as Map));
  }

  /// POST /api/users/register/ — returns 201 but NOT a token, so we log in
  /// straight afterwards to get one.
  Future<Me> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _post('/users/register/', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'confirm_password': password,
    });
    return login(email, password);
  }

  Future<bool> emailLoginEnabled() async {
    try {
      final r = await _get('/users/is-email-login');
      return r['emailLoginEnabled'] == true;
    } catch (_) {
      return true;
    }
  }

  // ── me ─────────────────────────────────────────────────────────────────────

  Future<Me> me() async =>
      Me.fromJson(Map<String, dynamic>.from(await _get('/users/') as Map));

  Future<void> updateName(String name) => _patch('/users/', {'name': name});

  /// POST creates, PATCH updates — the backend 400s if you POST twice.
  Future<Profile> saveProfile({
    required DateTime dateOfBirth,
    required String gender,
    int? existingId,
  }) async {
    final body = {
      'date_of_birthday': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender,
    };
    final r = existingId == null
        ? await _post('/users/profile/', body)
        : await _patch('/users/profile/$existingId/', body);
    return Profile.fromJson(Map<String, dynamic>.from(r as Map));
  }

  Future<Settings> saveSettings(Settings s) async {
    final r = s.id == null
        ? await _post('/users/setting/', s.toJson())
        : await _patch('/users/setting/${s.id}/', s.toJson());
    return Settings.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// Multipart upload. The server runs an OpenCV face check and returns 400
  /// "Sorry, face not found" if it can't find one — surface that verbatim.
  Future<PhotoItem> uploadPhoto(File file) async {
    final req = http.MultipartRequest('POST', _u('/users/images/'));
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('image', file.path));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final r = await http.Response.fromStream(streamed);
    return PhotoItem.fromJson(Map<String, dynamic>.from(_decode(r) as Map));
  }

  Future<void> deletePhoto(int id) => _delete('/users/image/$id/');

  Future<void> deleteAccount() => _delete('/users/delete/user/');

  Future<void> registerPushToken(String deviceId) =>
      _post('/users/device-token/data/', {'device_id': deviceId});

  // ── proximity + discovery ──────────────────────────────────────────────────

  /// POST /api/users/geo-data/
  /// The server does Point(coordinate), and PostGIS Point is (x, y) = (lon, lat).
  /// Sending [lat, lon] here silently puts everyone in the wrong hemisphere.
  Future<void> pushLocation({required double lat, required double lon}) =>
      _post('/users/geo-data/', {'coordinate': [lon, lat]});

  /// filter: 'geo' (gps + wifi), 'bts' (bluetooth + tight gps), 'all'
  Future<List<Candidate>> discover({String filter = 'geo'}) async {
    final q = {'filter': filter, if (Config.devMode) 'mode': 'dev'};
    final r = await _get('/users/filtered-list/', q) as List;
    return r
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> user(int id) async =>
      Map<String, dynamic>.from(await _get('/users/$id/') as Map);

  Future<void> ban(int id) => _post('/users/$id/ban/', {});

  Future<void> report(int id, String body) =>
      _post('/reports/$id/', {'body': body});

  // ── likes ──────────────────────────────────────────────────────────────────

  /// POST /api/likes/ — send_date defaults to now. A future date schedules the
  /// like (the backend supports it; the Figma calls it "Send a Like with timer").
  Future<Like> like(int receiverId, {DateTime? sendDate}) async {
    final r = await _post('/likes/', {
      'receiver_id': receiverId,
      'send_date': (sendDate ?? DateTime.now()).toUtc().toIso8601String(),
    });
    return Like.fromJson(Map<String, dynamic>.from(r as Map));
  }

  Future<void> unlike(int likeId) => _delete('/likes/$likeId/unlike/');

  /// GET /api/likes/ → { id, sent: [...], received: [...] }
  Future<({List<Like> sent, List<Like> received})> likes() async {
    final r = Map<String, dynamic>.from(await _get('/likes/') as Map);
    List<Like> parse(String k) => ((r[k] as List?) ?? [])
        .map((e) => Like.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (sent: parse('sent'), received: parse('received'));
  }

  // ── chat ───────────────────────────────────────────────────────────────────

  Future<List<ChatRoom>> chats() async {
    final r = await _get('/chats/') as List;
    return r
        .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChatRoom> chat(int id) async =>
      ChatRoom.fromJson(Map<String, dynamic>.from(await _get('/chats/$id/') as Map));

  /// Returned newest-first by the server (order_by('-created')).
  /// Fetching this also marks the partner's messages read.
  Future<List<Message>> messages(int chatId) async {
    final r = await _get('/chats/$chatId/messages/') as List;
    return r
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Message> sendMessage(int chatId, String body) async {
    final r = await _post('/chats/message/', {
      'chat_room_id': chatId,
      'body': body,
    });
    return Message.fromJson(Map<String, dynamic>.from(r as Map));
  }

  Future<void> extendChat(int chatId) =>
      _post('/chats/extend-time/', {'id': chatId});

  // ── history ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> history() async {
    final r = await _get('/histories/') as List;
    return r.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
