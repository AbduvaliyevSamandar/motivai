import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'user_scope.dart';

/// Token xavfsiz saqlanadi — telefon o'chirib yoqilsa ham, kesh tozalansa ham
class Storage {
  static final Storage _i = Storage._();
  factory Storage() => _i;
  Storage._();

  static const _sec = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock),
  );

  // ── TOKEN ─────────────────────────────────────────────
  Future<void>    saveToken(String t) =>
      _sec.write(key: K.tokenKey, value: t);

  Future<String?> getToken() =>
      _sec.read(key: K.tokenKey);

  Future<void>    clearToken() =>
      _sec.delete(key: K.tokenKey);

  // ── USER CACHE ────────────────────────────────────────
  Future<void> saveUser(Map<String, dynamic> u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(K.userKey, jsonEncode(u));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(K.userKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(K.userKey);
  }

  // ── CHAT HISTORY (per-user) ──────────────────────────
  String _chatKey() => UserScope.key('chat_history');

  Future<void> saveChat(List<Map<String, dynamic>> msgs) async {
    final p = await SharedPreferences.getInstance();
    // Faqat oxirgi 50 ta xabarni saqlash
    final trimmed = msgs.length > 50
        ? msgs.sublist(msgs.length - 50)
        : msgs;
    await p.setString(_chatKey(), jsonEncode(trimmed));
  }

  Future<List<Map<String, dynamic>>> loadChat() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_chatKey());
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearChat() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_chatKey());
  }

  // ── CLEAR ALL (logout) ────────────────────────────────
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
