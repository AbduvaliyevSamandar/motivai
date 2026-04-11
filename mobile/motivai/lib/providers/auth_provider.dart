// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final ApiService _api = ApiService();

  Future<void> init() async {
    await _api.init();
    final token = await _api.getToken();
    if (token != null) {
      try {
        final res = await _api.getMe();
        _user = UserModel.fromJson(res['data']['user']);
        _status = AuthStatus.authenticated;
      } catch (e) {
        await logout();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String language = 'uz',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.register({
        'name': name,
        'email': email,
        'password': password,
        'language': language,
      });
      
      final token = res['data']['token'];
      await _api.saveToken(token);
      _user = UserModel.fromJson(res['data']['user']);
      _status = AuthStatus.authenticated;
      await _cacheUser();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(email, password);
      final token = res['data']['token'];
      await _api.saveToken(token);
      _user = UserModel.fromJson(res['data']['user']);
      _status = AuthStatus.authenticated;
      await _cacheUser();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _api.updateProfile(data);
      _user = UserModel.fromJson(res['data']['user']);
      await _cacheUser();
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void updateUserXP(int newXp, int newLevel, int newStreak) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        avatar: _user!.avatar,
        language: _user!.language,
        country: _user!.country,
        xp: newXp,
        level: newLevel,
        streak: newStreak,
        totalTasksCompleted: _user!.totalTasksCompleted + 1,
        totalStudyMinutes: _user!.totalStudyMinutes,
        aiMessagesCount: _user!.aiMessagesCount,
        profile: _user!.profile,
        badges: _user!.badges,
      );
      notifyListeners();
    }
  }

  Future<void> _cacheUser() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode({
        'id': _user!.id,
        'name': _user!.name,
        'email': _user!.email,
      }));
    }
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('409')) return 'Bu email allaqachon ro\'yxatdan o\'tgan';
      if (str.contains('401')) return 'Email yoki parol noto\'g\'ri';
      if (str.contains('connection')) return 'Internet ulanishi yo\'q';
    }
    return 'Xatolik yuz berdi. Qayta urinib ko\'ring';
  }
}
