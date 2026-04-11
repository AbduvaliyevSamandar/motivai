// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Token expired - handle logout
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<void> init() async {
    _setupInterceptors();
  }

  // ========= AUTH =========
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
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

  // ========= AI CHAT =========
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? sessionId,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final res = await _dio.post('/ai/chat', data: {
      'message': message,
      'session_id': sessionId,
      'conversation_history': history,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getChatHistory({String? sessionId, int limit = 50}) async {
    final res = await _dio.get('/ai/history', queryParameters: {
      if (sessionId != null) 'session_id': sessionId,
      'limit': limit,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getChatSessions() async {
    final res = await _dio.get('/ai/sessions');
    return res.data;
  }

  Future<Map<String, dynamic>> getQuickMotivation() async {
    final res = await _dio.post('/ai/quick-motivate');
    return res.data;
  }

  Future<Map<String, dynamic>> analyzeProgress() async {
    final res = await _dio.post('/ai/analyze-progress');
    return res.data;
  }

  Future<Map<String, dynamic>> getDailyTip({String category = 'academic'}) async {
    final res = await _dio.get('/ai/daily-tip', queryParameters: {'category': category});
    return res.data;
  }

  // ========= PLANS =========
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async {
    final res = await _dio.post('/plans/', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getPlans({bool? isActive, String? category}) async {
    final res = await _dio.get('/plans/', queryParameters: {
      if (isActive != null) 'is_active': isActive,
      if (category != null) 'category': category,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getPlan(String planId) async {
    final res = await _dio.get('/plans/$planId');
    return res.data;
  }

  Future<Map<String, dynamic>> completeTask(
    String planId, String taskId, {int? studyMinutes}
  ) async {
    final res = await _dio.post('/plans/$planId/complete-task', data: {
      'task_id': taskId,
      if (studyMinutes != null) 'study_minutes': studyMinutes,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> deletePlan(String planId) async {
    final res = await _dio.delete('/plans/$planId');
    return res.data;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/plans/stats/summary');
    return res.data;
  }

  // ========= LEADERBOARD =========
  Future<Map<String, dynamic>> getLeaderboard({String period = 'weekly'}) async {
    final res = await _dio.get('/leaderboard/', queryParameters: {'period': period});
    return res.data;
  }

  Future<Map<String, dynamic>> getMyRank() async {
    final res = await _dio.get('/leaderboard/my-rank');
    return res.data;
  }

  // ========= PROGRESS =========
  Future<Map<String, dynamic>> getProgress({int days = 7}) async {
    final res = await _dio.get('/progress/', queryParameters: {'days': days});
    return res.data;
  }

  Future<Map<String, dynamic>> getHeatmap() async {
    final res = await _dio.get('/progress/heatmap');
    return res.data;
  }

  // ========= TOKEN MANAGEMENT =========
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    _setupInterceptors();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
}
