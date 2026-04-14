import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  Map<String, dynamic>? _user;
  String? _token;
  bool    _loading = true; // splash uchun
  String? _error;

  // ── Getters ───────────────────────────────────────────
  bool    get isLoggedIn => _token != null && _user != null;
  bool    get isLoading  => _loading;
  String? get token      => _token;
  String? get error      => _error;
  Map<String, dynamic>? get user => _user;

  String get name    => _user?['full_name'] ?? _user?['username'] ?? '';
  String get email   => _user?['email']     ?? '';
  int    get points  => (_user?['points']   ?? 0)  as int;
  int    get level   => (_user?['level']    ?? 1)  as int;
  int    get streak  => (_user?['streak']   ?? 0)  as int;
  int    get totalTasks => (_user?['total_tasks_completed'] ?? 0) as int;
  String get role    => _user?['role']      ?? 'student';
  bool   get isAdmin => role == 'admin';
  List   get achiev  => (_user?['achievements'] as List?) ?? [];

  String get levelEmoji {
    if (level >= 15) return '💎';
    if (level >= 10) return '🔥';
    if (level >= 7)  return '⭐';
    if (level >= 4)  return '🚀';
    if (level >= 2)  return '📚';
    return '🌱';
  }

  // ── INIT — app ochilganda token tekshiradi ────────────
  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final tok = await _store.getToken();
      if (tok != null) {
        _token = tok;
        // Keshdan tez yuklash
        final cached = await _store.getUser();
        if (cached != null) _user = cached;
        // Backgroundda serverdan yangilash
        _refresh().catchError((_) {});
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

  Future<void> _refresh() async {
    try {
      final data = await _api.get(K.me);
      _user = (data as Map).cast<String, dynamic>();
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
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.post(
        K.login,
        {'email': email, 'password': password},
        auth: false,
      );
      _token = data['access_token']?.toString();
      _user  = (data['user'] as Map?)?.cast<String, dynamic>();

      if (_token == null) throw ApiError('Token olinmadi');

      // Profil alohida bo'lsa
      if (_user == null) {
        await _store.saveToken(_token!);
        final d = await _api.get(K.me);
        _user = (d as Map).cast<String, dynamic>();
      }

      await _store.saveToken(_token!);
      await _store.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
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
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.post(
        K.register,
        {
          'full_name':       fullName,
          'username':        username,
          'email':           email,
          'password':        password,
          'subjects':        subjects,
          'difficulty_pref': difficulty,
        },
        auth: false,
      );
      _token = data['access_token']?.toString();
      _user  = (data['user'] as Map?)?.cast<String, dynamic>();

      if (_token == null) throw ApiError('Token olinmadi');

      if (_user == null) {
        await _store.saveToken(_token!);
        final d = await _api.get(K.me);
        _user = (d as Map).cast<String, dynamic>();
      }

      await _store.saveToken(_token!);
      await _store.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────
  // Consumer<AuthProvider> avtomatik LoginScreen ko'rsatadi
  Future<void> logout() async {
    try {
      await _api.post(K.logout, {});
    } catch (_) {}
    await _store.clearAll();
    _token = null;
    _user  = null;
    notifyListeners();
  }

  // ── REFRESH ───────────────────────────────────────────
  Future<void> refresh() async => _refresh();

  void updateLocal(Map<String, dynamic> patch) {
    _user = {...?_user, ...patch};
    _store.saveUser(_user!);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
