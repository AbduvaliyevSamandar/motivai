import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token storage
  static Future<void> saveToken(String token) async {
    await _prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    return _prefs.getString('access_token');
  }

  static Future<void> saveRefreshToken(String token) async {
    await _prefs.setString('refresh_token', token);
  }

  static Future<String?> getRefreshToken() async {
    return _prefs.getString('refresh_token');
  }

  // User data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('user', json.encode(user));
  }

  static Map<String, dynamic>? getUser() {
    final str = _prefs.getString('user');
    if (str == null) return null;
    return json.decode(str);
  }

  static bool isLoggedIn() {
    return _prefs.getString('access_token') != null;
  }

  static Future<void> clearAuth() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('user');
  }

  // Settings
  static Future<void> setLanguage(String lang) async {
    await _prefs.setString('language', lang);
  }

  static String getLanguage() {
    return _prefs.getString('language') ?? 'uz';
  }

  static Future<void> setTheme(bool isDark) async {
    await _prefs.setBool('isDark', isDark);
  }

  static bool getTheme() {
    return _prefs.getBool('isDark') ?? true;
  }

  // Chat sessions
  static Future<void> saveLastSession(String sessionId) async {
    await _prefs.setString('last_session_id', sessionId);
  }

  static String? getLastSession() {
    return _prefs.getString('last_session_id');
  }

  // Onboarding
  static Future<void> setOnboardingDone() async {
    await _prefs.setBool('onboarding_done', true);
  }

  static bool isOnboardingDone() {
    return _prefs.getBool('onboarding_done') ?? false;
  }
}
