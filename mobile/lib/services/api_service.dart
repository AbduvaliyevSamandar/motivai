import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

const String _baseUrl = 'http://localhost:8000/api/v1';
// Android emulator: 'http://10.0.2.2:8000/api/v1'
// iOS simulator: 'http://localhost:8000/api/v1'

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await StorageService.getToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          handler.next(error);
        },
      ),
    );

    // Logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => print('🌐 $o'),
      ),
    );
  }

  // ==================== AUTH ====================
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String language = 'uz',
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'language': language,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {

    final res = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    // Backend response: { access_token, token_type, user }
    final token = res.data['data']['token'];

    if (token != null) {
      await StorageService.saveToken(token);
    }

    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/auth/profile', data: data);
    return res.data;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newToken = response.data['data']['access_token'];
      await StorageService.saveToken(newToken);
      return true;
    } catch (e) {
      await StorageService.clearAuth();
      return false;
    }
  }

  // ==================== AI ====================
  Future<Map<String, dynamic>> chat({
    required String message,
    String? sessionId,
    List<Map<String, dynamic>> conversationHistory = const [],
  }) async {
    final token = await StorageService.getToken();
    final res = await _dio.post(
      '/ai/chat',
      data: {
        'message': message,
        'session_id': sessionId,
        'conversation_history': conversationHistory,
      },
      options: Options(
        headers: {
          'Authorization': token != null ? 'Bearer $token' : null,
        },
      ),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> getChatHistory({String? sessionId, int limit = 50}) async {
    final params = {'limit': limit};
    if (sessionId != null) params['session_id'] = sessionId as int;
    final res = await _dio.get('/ai/history', queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> quickMotivate({String? prompt}) async {
    final res = await _dio.post(
      '/ai/quick-motivate',
      data: {
        if (prompt != null) 'prompt': prompt,
      },
    );
    return res.data;
  }

  Future<Map<String, dynamic>> analyzeProgress() async {
    final res = await _dio.post('/ai/analyze-progress');
    return res.data;
  }

  // ==================== PLANS ====================
  Future<Map<String, dynamic>> getPlans({bool activeOnly = true}) async {
    final res = await _dio.get('/plans/', queryParameters: {'active_only': activeOnly});
    return res.data;
  }

  Future<Map<String, dynamic>> getPlan(String planId) async {
    final res = await _dio.get('/plans/$planId');
    return res.data;
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async {
    final res = await _dio.post('/plans/', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> completeTask({
    required String planId,
    required String taskId,
    int studyMinutes = 0,
  }) async {
    final res = await _dio.post('/plans/$planId/complete-task', data: {
      'task_id': taskId,
      'study_minutes': studyMinutes,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> deletePlan(String planId) async {
    final res = await _dio.delete('/plans/$planId');
    return res.data;
  }

  // ==================== PROGRESS ====================
  Future<Map<String, dynamic>> getProgress({int days = 30}) async {
    final res = await _dio.get('/progress/', queryParameters: {'days': days});
    return res.data;
  }

  Future<Map<String, dynamic>> getProgressSummary() async {
    final res = await _dio.get('/progress/summary');
    return res.data;
  }

  // ==================== LEADERBOARD ====================
  Future<Map<String, dynamic>> getLeaderboard({String period = 'weekly', String? country, int limit = 50}) async {
    final params = {'period': period, 'limit': limit};
    if (country != null) params['country'] = country;
    final res = await _dio.get('/leaderboard/', queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> getMyRank() async {
    final res = await _dio.get('/leaderboard/my-rank');
    return res.data;
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final res = await _dio.get('/users/stats');
    return res.data;
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());