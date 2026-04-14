import 'package:flutter/material.dart';
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

  bool    get isLoggedIn  => _token != null && _user != null;
  bool    get isLoading   => _loading;
  String? get token       => _token;
  String? get error       => _error;
  Map<String, dynamic>? get user => _user;

  String get name       => _user?['full_name'] ?? _user?['username'] ?? '';
  String get email      => _user?['email']     ?? '';
  int    get points     => (_user?['points']   ?? 0) as int;
  int    get level      => (_user?['level']    ?? 1) as int;
  int    get streak     => (_user?['streak']   ?? 0) as int;
  int    get totalTasks => (_user?['total_tasks_completed'] ?? 0) as int;
  String get role       => _user?['role']      ?? 'student';
  bool   get isAdmin    => role == 'admin';
  List   get achiev     => (_user?['achievements'] as List?) ?? [];
  String get userId     => _user?['id']?.toString() ?? _user?['_id']?.toString() ?? '';

  String get levelEmoji {
    if (level >= 15) return '💎';
    if (level >= 10) return '🔥';
    if (level >= 7)  return '⭐';
    if (level >= 4)  return '🚀';
    if (level >= 2)  return '📚';
    return '🌱';
  }

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

  Future<void> _refreshProfile() async {
  try {
    final res = await _api.get(K.me);
    // Backend: {"success":true, "data": {"user":...}}
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
    // Backend: {"success":true, "data": {"token":..., "user":...}}
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
  List<String> subjects  = const [],
  String difficulty      = 'medium',
}) async {
  _error   = null;
  _loading = true;
  notifyListeners();
  try {
    // Backend faqat: name, email, password, language, country
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
    // Backend: {"success":true, "data": {"token":..., "user":...}}
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

  // ── LOGOUT ────────────────────────────────────────────
  Future<void> logout() async {
    try { await _api.post(K.logout, {}); } catch (_) {}
    await _store.clearAll();
    _token = null;
    _user  = null;
    notifyListeners();
  }

  Future<void> refresh() async => _refreshProfile();

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