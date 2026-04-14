import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final tokenExists = await ApiService.loadTokens();
      
      // Only try to fetch user if we have a token
      if (tokenExists) {
        try {
          _user = await ApiService.getCurrentUser();
          _isAuthenticated = true;
        } catch (e) {
          // Token might be expired, clear it
          print('Failed to fetch user profile: $e');
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        // No token saved, user needs to login
        _isAuthenticated = false;
        _user = null;
      }
      notifyListeners();
    } catch (e) {
      print('Auth initialization error: $e');
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await ApiService.register(
        email: email,
        username: username,
        fullName: fullName,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await ApiService.login(
        email: email,
        password: password,
      );

      // Handle backend response structure: {success, message, data: {token, user}}
      print('Login response: $result');
      
      final data = result['data'] ?? result;
      
      if (data['token'] == null && data['access_token'] == null) {
        throw Exception('No access token in response');
      }

      if (data['user'] == null) {
        throw Exception('No user data in response: $data');
      }

      // Get token from either 'token' or 'access_token' field
      _accessToken = data['token'] ?? data['access_token'];
      
      try {
        _user = User.fromJson(data['user']);
        print('User parsed successfully: ${_user?.email}');
      } catch (e) {
        print('Error parsing user data: $e');
        print('User data: ${data['user']}');
        throw Exception('Invalid user data format: $e');
      }
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
      _user = null;
      _accessToken = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.updateProfile(
        fullName: fullName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      _user = await ApiService.getCurrentUser();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
