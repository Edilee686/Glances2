import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

/// App-wide auth + location state. Deliberately a plain ChangeNotifier — no
/// state-management package — so the MVP has as few moving parts as possible.
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  static const _tokenKey = 'glances_jwt';

  Me? me;
  bool booting = true;
  String? locationStatus;

  Timer? _locationTimer;

  bool get signedIn => me != null;

  // ── boot / auth ────────────────────────────────────────────────────────────

  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null) {
      Api.instance.token = saved;
      try {
        me = await Api.instance.me();
        startLocationUpdates();
      } catch (_) {
        // Token rejected or server unreachable — fall back to signed out.
        Api.instance.token = null;
        await prefs.remove(_tokenKey);
      }
    }
    booting = false;
    notifyListeners();
  }

  Future<void> _persistToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = Api.instance.token;
    if (t == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, t);
    }
  }

  Future<void> login(String email, String password) async {
    me = await Api.instance.login(email, password);
    await _persistToken();
    startLocationUpdates();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    me = await Api.instance.register(name: name, email: email, password: password);
    await _persistToken();
    startLocationUpdates();
    notifyListeners();
  }

  Future<void> refresh() async {
    me = await Api.instance.me();
    notifyListeners();
  }

  Future<void> signOut() async {
    stopLocationUpdates();
    Api.instance.token = null;
    me = null;
    await _persistToken();
    notifyListeners();
  }

  // ── location ───────────────────────────────────────────────────────────────

  /// Glances is a proximity app: if the server has no recent coordinate for you
  /// it will never place you in anyone's feed, and your own feed comes back
  /// empty. So we push a position on login and then on a timer.
  ///
  /// This is the naive version — a fixed interval, foreground only. The
  /// adaptive, battery-aware, background-capable version is the proximity
  /// engine milestone; see the Phase 1 analysis §7.
  void startLocationUpdates({Duration every = const Duration(seconds: 45)}) {
    _locationTimer?.cancel();
    pushLocationNow();
    _locationTimer = Timer.periodic(every, (_) => pushLocationNow());
  }

  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<bool> pushLocationNow() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationStatus('Location services are turned off on this phone');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationStatus('Location permission denied — nobody can find you');
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      await Api.instance.pushLocation(lat: pos.latitude, lon: pos.longitude);
      _setLocationStatus(null);
      return true;
    } catch (e) {
      _setLocationStatus('Location update failed: $e');
      return false;
    }
  }

  void _setLocationStatus(String? s) {
    if (locationStatus == s) return;
    locationStatus = s;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
