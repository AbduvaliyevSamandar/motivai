import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Local server for testing
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static String? _accessToken;
  static String? _refreshToken;

  // Auth Endpoints
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': fullName,
          'email': email,
          'password': password,
          'language': 'uz',
          'country': 'UZ',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle nested data structure: {success, message, data: {token, user}}
        final tokenData = data['data'] ?? data;
        
        _accessToken = tokenData['token'] ?? tokenData['access_token'];
        _refreshToken = tokenData['refresh_token']; // Might be null
        
        // Store tokens
        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('refresh_token', _refreshToken!);
        }
        
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      _accessToken = null;
      _refreshToken = null;
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }

  static Future<bool> loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      return _accessToken != null; // Return true if token exists
    } catch (e) {
      print('Error loading tokens: $e');
      return false;
    }
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // User Endpoints
  static Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  static Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: _getHeaders(),
        body: jsonEncode({
          'full_name': fullName,
          'bio': bio,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/stats/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting stats: $e');
    }
  }

  // Task Endpoints
  static Future<List<Task>> getTasks({
    String? category,
    String? difficulty,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      String url = '$baseUrl/tasks?skip=$skip&limit=$limit';
      if (category != null) url += '&category=$category';
      if (difficulty != null) url += '&difficulty=$difficulty';

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasks = (data['tasks'] as List)
            .map((task) => Task.fromJson(task))
            .toList();
        return tasks;
      } else {
        throw Exception('Failed to get tasks: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting tasks: $e');
    }
  }

  static Future<Task> getTask(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting task: $e');
    }
  }

  // Progress Endpoints
  static Future<Map<String, dynamic>> startTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/start'),
        headers: _getHeaders(),
        body: jsonEncode({'task_id': taskId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to start task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting task: $e');
    }
  }

  static Future<Map<String, dynamic>> completeTask(String taskId, {String? notes}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/complete'),
        headers: _getHeaders(),
        body: jsonEncode({
          'task_id': taskId,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to complete task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing task: $e');
    }
  }

  static Future<List<Progress>> getUserProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/user/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final progress = (data['progress'] as List)
            .map((p) => Progress.fromJson(p))
            .toList();
        return progress;
      } else {
        throw Exception('Failed to get progress: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting progress: $e');
    }
  }

  static Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/stats/weekly'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get weekly stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting weekly stats: $e');
    }
  }

  // AI Endpoints
  static Future<MotivationPlan> getMotivationPlan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/motivation-plan'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return MotivationPlan.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get motivation plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting motivation plan: $e');
    }
  }

  static Future<Map<String, dynamic>> getDailyInsight() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/daily-insight'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get daily insight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting daily insight: $e');
    }
  }

  static Future<List<MotivationPlan>> getRecommendations({int count = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/recommendations?count=$count'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plans = (data['recommendations'] as List)
            .map((p) => MotivationPlan.fromJson(p))
            .toList();
        return plans;
      } else {
        throw Exception('Failed to get recommendations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting recommendations: $e');
    }
  }

  // Leaderboard Endpoints
  static Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/global?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entries = (data['leaderboard'] as List)
            .map((entry) => LeaderboardEntry.fromJson(entry))
            .toList();
        return entries;
      } else {
        throw Exception('Failed to get leaderboard: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting leaderboard: $e');
    }
  }

  static Future<LeaderboardEntry> getUserRank() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/user-rank'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return LeaderboardEntry.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user rank: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user rank: $e');
    }
  }

  static Future<Map<String, dynamic>> chatWithAI({
    required String message,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final body = {
        'message': message,
        'conversation_history': conversationHistory ?? [],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to chat with AI: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error chatting with AI: $e');
    }
  }
}
