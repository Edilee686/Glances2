import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence layer. Everything the app remembers lives here.
class Store {
  Store(this._prefs);

  static const _key = 'glances.v1';

  final SharedPreferences _prefs;
  Map<String, dynamic> _data = {};

  static Future<Store> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = Store(prefs);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        store._data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        store._data = {};
      }
    }
    return store;
  }

  T? read<T>(String key) => _data[key] as T?;

  List<String> readList(String key) =>
      (_data[key] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

  Map<String, dynamic> readMap(String key) =>
      Map<String, dynamic>.from(_data[key] as Map<String, dynamic>? ?? const {});

  void write(String key, Object? value) {
    _data[key] = value;
    _flush();
  }

  void writeAll(Map<String, Object?> values) {
    _data.addAll(values);
    _flush();
  }

  Future<void> wipe() async {
    _data = {};
    await _prefs.remove(_key);
  }

  void _flush() {
    _prefs.setString(_key, jsonEncode(_data));
  }
}
