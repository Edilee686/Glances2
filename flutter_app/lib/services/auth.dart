import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';

enum AuthProvider { phone, google, facebook }

extension AuthProviderName on AuthProvider {
  String get key => switch (this) {
        AuthProvider.phone => 'phone',
        AuthProvider.google => 'google',
        AuthProvider.facebook => 'facebook',
      };
}

class AuthResult {
  AuthResult({required this.accountId, required this.isNew});
  final String accountId;
  final bool isNew;
}

/// Account handling for a device-only build. Registration and sign-in are real
/// - accounts are rows in the database and the session survives restarts - but
/// there is no network, so the SMS code is generated and checked locally and
/// the social buttons register a device-scoped identity instead of doing OAuth.
class Auth {
  Auth(this._db, this._prefs);

  static const _sessionKey = 'glances.session.accountId';

  final GlancesDb _db;
  final SharedPreferences _prefs;

  String? _pendingPhone;
  String? _pendingCode;
  DateTime? _codeSentAt;

  String? get accountId => _prefs.getString(_sessionKey);
  bool get signedIn => accountId != null;
  String? get pendingPhone => _pendingPhone;

  /// The code we would have texted. Surfaced in the UI because this build has
  /// no SMS gateway - replace with your provider's send call.
  String? get lastCode => _pendingCode;

  /// Step one of phone sign-in: generate and "send" a six digit code.
  String requestCode(String phone) {
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    _pendingPhone = phone;
    _pendingCode = code;
    _codeSentAt = DateTime.now();
    return code;
  }

  bool get codeExpired {
    final sent = _codeSentAt;
    return sent == null || DateTime.now().difference(sent) > const Duration(minutes: 10);
  }

  /// Step two: verify and sign in, creating the account on first use.
  Future<AuthResult?> verifyCode(String entered) async {
    final phone = _pendingPhone;
    if (phone == null || codeExpired) return null;
    if (entered.trim() != _pendingCode) return null;
    _pendingCode = null;
    return _signIn(AuthProvider.phone, phone, secret: null);
  }

  Future<AuthResult> signInWith(AuthProvider provider) async {
    // Without OAuth we mint a stable per-device identity for the provider.
    final key = 'glances.deviceid.' + provider.key;
    var identifier = _prefs.getString(key);
    if (identifier == null) {
      identifier = provider.key + '_' + _randomId();
      await _prefs.setString(key, identifier);
    }
    return _signIn(provider, identifier, secret: null);
  }

  Future<AuthResult> _signIn(AuthProvider provider, String identifier, {String? secret}) async {
    final existing = await _db.findAccount(provider.key, identifier);
    if (existing != null) {
      final id = existing['id'] as String;
      await _prefs.setString(_sessionKey, id);
      return AuthResult(accountId: id, isNew: false);
    }
    final id = await _db.createAccount(
      provider.key,
      identifier,
      secret == null ? null : sha256.convert(utf8.encode(secret)).toString(),
    );
    await _prefs.setString(_sessionKey, id);
    return AuthResult(accountId: id, isNew: true);
  }

  Future<void> signOut() async {
    _pendingPhone = null;
    _pendingCode = null;
    await _prefs.remove(_sessionKey);
  }

  Future<void> deleteAccount() async {
    final id = accountId;
    if (id != null) await _db.deleteAccount(id);
    await signOut();
  }

  static String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
