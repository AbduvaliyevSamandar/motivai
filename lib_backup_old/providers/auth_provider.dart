import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  Map<String, dynamic>? _user;
  String? _token;
  bool    _loading = true; // true = splash screen ko'rsatiladi
  String? _error;

  // ── GETTERS ───────────────────────────────────────────
  bool   get isLoggedIn => _token != null && _user != null;
  bool   get isLoading  => _loading;
  String? get token     => _token;
  String? get error     => _error;
  Map<String, dynamic>? get user => _user;

  String get name    => _user?['full_name'] ?? _user?['username'] ?? 'Foydalanuvchi';
  String get email   => _user?['email'] ?? '';
  int    get points  => (_user?['points'] ?? 0) as int;
  int    get level   => (_user?['level']  ?? 1) as int;
  int    get streak  => (_user?['streak'] ?? 0) as int;
  String get role    => _user?['role'] ?? 'student';
  bool   get isAdmin => role == 'admin';
  List   get achiev  => _user?['achievements'] ?? [];

  // Daraja emojisi
  String get levelEmoji {
    if (level >= 15) return '💎';
    if (level >= 10) return '🔥';
    if (level >= 7)  return '⭐';
    if (level >= 4)  return '🚀';
    if (level >= 2)  return '📚';
    return '🌱';
  }

  // ── INIT — app ochilganda token tekshiradi ─────────────
  AuthProvider() { _init(); }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final savedToken = await _store.getToken();
      if (savedToken != null) {
        _token = savedToken;
        // Keshdan foydalanuvchini yuklaymiz (tez)
        final cached = await _store.getUser();
        if (cached != null) _user = cached;
        // Serverdan yangilaymiz (background)
        _refreshProfile().catchError((_) {});
      }
    } catch (_) {
      await _store.clearAll();
      _token = null;
      _user  = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final data = await _api.get(K.me);
      _user = data as Map<String, dynamic>;
      await _store.saveUser(_user!);
      notifyListeners();
    } on AuthError {
      // Token eskirgan
      await _store.clearAll();
      _token = null;
      _user  = null;
      notifyListeners();
    }
  }

  // ── LOGIN ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.post(
        K.login,
        {'email': email, 'password': password},
        auth: false,
      );

      _token = data['access_token'] as String;
      _user  = (data['user'] as Map?)?.cast<String, dynamic>();

      // Profil alohida endpoint bo'lsa
      if (_user == null) {
        final old = _token;
        await _store.saveToken(old!);
        _user = await _api.get(K.me) as Map<String, dynamic>;
      }

      await _store.saveToken(_token!);
      await _store.saveUser(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── REGISTER ──────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    List<String> subjects = const [],
    String difficulty = 'medium',
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.post(K.register, {
        'full_name':       fullName,
        'username':        username,
        'email':           email,
        'password':        password,
        'subjects':        subjects,
        'difficulty_pref': difficulty,
      }, auth: false);

      _token = data['access_token'] as String;
      _user  = (data['user'] as Map?)?.cast<String, dynamic>();
      if (_user == null && _token != null) {
        await _store.saveToken(_token!);
        _user = await _api.get(K.me) as Map<String, dynamic>;
      }

      await _store.saveToken(_token!);
      await _store.saveUser(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────
  /// Bu yerda Navigator ishlatilmaydi — Consumer<AuthProvider>
  /// LoginScreen ga avtomatik yo'naltiradi
  Future<void> logout() async {
    try { await _api.post(K.logout, {}); } catch (_) {}
    await _store.clearAll();
    _token = null;
    _user  = null;
    notifyListeners(); // → main.dart Consumer LoginScreen ko'rsatadi
  }

  // ── REFRESH ───────────────────────────────────────────
  Future<void> refresh() async => _refreshProfile();

  void updateLocal(Map<String, dynamic> patch) {
    _user = {...?_user, ...patch};
    _store.saveUser(_user!);
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
}
