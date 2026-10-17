import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cook_session.dart';

/// Persists the active cooking session (recipe + step) so cooking
/// can be resumed after leaving the app or navigating away.
class CookSessionRepository {
  static const String _key = 'sprout_active_cook_session';

  Future<void> saveSession(CookSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(session.toJson()));
    } catch (_) {
      // Storage unavailable — session simply won't persist
    }
  }

  Future<CookSession?> fetchSession() async {
    String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_key);
    } catch (_) {
      return null;
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      return CookSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing to clear
    }
  }
}
