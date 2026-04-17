import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  Map<String, dynamic>? _user;
  String? _token;
  bool    _loading = true;
  String? _error;

  // ── Getters ───────────────────────────────────────────
  bool    get isLoggedIn => _token != null && _user != null;
  bool    get isLoading  => _loading;
  String? get token      => _token;
  String? get error      => _error;
  Map<String, dynamic>? get user => _user;

  String get name       => _user?['name'] ?? _user?['full_name'] ?? '';
  String get email      => _user?['email'] ?? '';
  int    get points     => (_user?['xp'] ?? _user?['points'] ?? 0) as int;
  int    get level      => (_user?['level']  ?? 1) as int;
  int    get streak     => (_user?['streak'] ?? 0) as int;
  int    get totalTasks => (_user?['total_tasks_completed'] ?? 0) as int;
  String get role       => _user?['role'] ?? 'student';
  bool   get isAdmin    => role == 'admin';
  List   get achiev     => (_user?['badges'] as List?) ?? [];
  String get userId     => _user?['_id']?.toString() ?? '';

  String get levelEmoji {
    if (level >= 15) return '💎';
    if (level >= 10) return '🔥';
    if (level >= 7)  return '⭐';
    if (level >= 4)  return '🚀';
    if (level >= 2)  return '📚';
    return '🌱';
  }

  String? get avatarUrl => _user?['avatar'] as String?;

  // ── INIT ──────────────────────────────────────────────
  AuthProvider() { _init(); }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final tok = await _store.getToken();
      if (tok != null) {
        _token = tok;
        final cached = await _store.getUser();
        if (cached != null) _user = cached;
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

  // ── REFRESH PROFILE ───────────────────────────────────
  Future<void> _refreshProfile() async {
    try {
      final res = await _api.get(K.me);
      // Backend: {"success":true, "data": {"user":{...}}}
      final data = res['data'] as Map?;
      final userMap = data?['user'] as Map?;
      if (userMap != null) {
        _user = userMap.cast<String, dynamic>();
        await _store.saveUser(_user!);
        notifyListeners();
      }
    } on AuthError {
      await _store.clearAll();
      _token = null;
      _user  = null;
      notifyListeners();
    }
  }

  // ── LOGIN ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _error   = null;
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post(
        K.login,
        {'email': email, 'password': password},
        auth: false,
      );
      // Backend: {"success":true, "data": {"token":"...", "user":{...}}}
      final data = res['data'] as Map;
      _token = data['token']?.toString();
      if (_token == null) throw ApiError('Token olinmadi');

      final userMap = data['user'] as Map?;
      _user = userMap?.cast<String, dynamic>();

      await _store.saveToken(_token!);
      if (_user != null) await _store.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error   = e.toString();
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
  }) async {
    _error   = null;
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post(
        K.register,
        {
          'name':     fullName,
          'email':    email,
          'password': password,
          'language': 'uz',
          'country':  'UZ',
        },
        auth: false,
      );
      // Backend: {"success":true, "data": {"token":"...", "user":{...}}}
      final data = res['data'] as Map;
      _token = data['token']?.toString();
      if (_token == null) throw ApiError('Token olinmadi');

      final userMap = data['user'] as Map?;
      _user = userMap?.cast<String, dynamic>();

      await _store.saveToken(_token!);
      if (_user != null) await _store.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error   = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── CHANGE PASSWORD ───────────────────────────────────
  Future<bool> changePassword(String current, String newPass) async {
    _error = null;
    try {
      await _api.put('/auth/change-password', {
        'current_password': current,
        'new_password': newPass,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE PROFILE ────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> patch) async {
    _error = null;
    try {
      final res = await _api.put(K.profile, patch);
      final data = res['data'] as Map?;
      final userMap = data?['user'] as Map?;
      if (userMap != null) {
        _user = userMap.cast<String, dynamic>();
        await _store.saveUser(_user!);
      } else {
        _user = {...?_user, ...patch};
        await _store.saveUser(_user!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────
  Future<void> logout() async {
    try { await _api.post(K.logout, {}); } catch (_) {}
    await _store.clearAll();
    _token = null;
    _user  = null;
    notifyListeners();
  }

  // ── REFRESH ───────────────────────────────────────────
  Future<void> refresh() async => _refreshProfile();

  // ── UPDATE LOCAL ──────────────────────────────────────
  void updateLocal(Map<String, dynamic> patch) {
    _user = {...?_user, ...patch};
    _store.saveUser(_user!);
    notifyListeners();
  }

  // ── CLEAR ERROR ───────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── AVATAR (local) ────────────────────────────────────
  Future<void> updateAvatar(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('motivai_avatar_local', path);
    notifyListeners();
  }

  Future<String?> getLocalAvatar() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('motivai_avatar_local');
  }
}
