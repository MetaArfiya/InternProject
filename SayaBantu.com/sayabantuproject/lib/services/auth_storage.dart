import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

/// Auth storage PER-TAB di web (sessionStorage).
/// Di mobile/desktop pakai in-memory cache.
class AuthStorage {
  AuthStorage._();

  static final Map<String, String> _mem = {};

  static String? getString(String key) {
    if (kIsWeb) return web.window.sessionStorage.getItem(key);
    return _mem[key];
  }

  static void setString(String key, String value) {
    if (kIsWeb) {
      web.window.sessionStorage.setItem(key, value);
    } else {
      _mem[key] = value;
    }
  }

  static bool? getBool(String key) {
    final v = getString(key);
    if (v == null) return null;
    return v == 'true';
  }

  static void setBool(String key, bool value) =>
      setString(key, value.toString());

  static void remove(String key) {
    if (kIsWeb) {
      web.window.sessionStorage.removeItem(key);
    } else {
      _mem.remove(key);
    }
  }

  static void clear() {
    if (kIsWeb) {
      web.window.sessionStorage.clear();
    } else {
      _mem.clear();
    }
  }
}