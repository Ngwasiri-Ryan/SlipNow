import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app snapshot on-device as a single JSON blob.
class LocalStore {
  LocalStore(this._prefs);

  static const _key = 'slipnow_app_v7';
  static const _chatKey = 'slipnow_chat_v1';

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  Map<String, dynamic>? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> data) => _prefs.setString(_key, jsonEncode(data));

  /// Support chat history, kept apart from the main snapshot because it grows.
  List<dynamic> readChat() {
    final raw = _prefs.getString(_chatKey);
    if (raw == null) return const [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeChat(List<Map<String, dynamic>> messages) => _prefs.setString(_chatKey, jsonEncode(messages));

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_chatKey);
  }
}
