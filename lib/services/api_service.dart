import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://motivai-20s9.onrender.com/api/v1';
  static String? _accessToken;

  // ── Auth ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String email,
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final tokenData = data['data'] ?? data;
        _accessToken = tokenData['token']?.toString();
        if (_accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
        }
        return data;
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
        // Backend: {"success":true, "data": {"token":"...", "user":{...}}}
        final tokenData = data['data'] ?? data;
        _accessToken = tokenData['token']?.toString();

        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('access_token', _accessToken!);
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
      _accessToken = null;
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }

  static Future<bool> loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      return _accessToken != null;
    } catch (e) {
      return false;
    }
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // ── User ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend: {"success":true, "data": {"user":{...}}}
        final userData = data['data']?['user'] ?? data;
        return userData;
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  static Future<void> updateProfile({
    required String fullName,
    String? avatar,
    String? language,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': fullName,
          if (avatar != null) 'avatar': avatar,
          if (language != null) 'language': language,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getPlanStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plans/stats/summary'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to get stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting stats: $e');
    }
  }

  // ── Plans ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPlans({bool? isActive, String? category}) async {
    try {
      String url = '$baseUrl/plans';
      final params = <String>[];
      if (isActive != null) params.add('is_active=$isActive');
      if (category != null) params.add('category=$category');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plans = data['data']?['plans'] ?? data['plans'] ?? [];
        return List<Map<String, dynamic>>.from(plans);
      } else {
        throw Exception('Failed to get plans: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting plans: $e');
    }
  }

  static Future<Map<String, dynamic>> completeTask(String planId, String taskId, {int? studyMinutes}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plans/$planId/complete-task'),
        headers: _getHeaders(),
        body: jsonEncode({
          'task_id': taskId,
          if (studyMinutes != null) 'study_minutes': studyMinutes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to complete task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing task: $e');
    }
  }

  // ── Progress ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getProgress({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress?days=$days'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to get progress: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting progress: $e');
    }
  }

  static Future<Map<String, dynamic>> getHeatmap() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/heatmap'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to get heatmap: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting heatmap: $e');
    }
  }

  // ── AI ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDailyInsight() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/daily-insight'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to get daily insight: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting daily insight: $e');
    }
  }

  // ── Leaderboard ───────────────────────────────────────
  static Future<List<LbEntry>> getLeaderboard({String period = 'weekly', int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard?period=$period&limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lbData = data['data'] ?? data;
        final entries = (lbData['leaderboard'] as List)
            .map((entry) => LbEntry.fromJson(entry))
            .toList();
        return entries;
      } else {
        throw Exception('Failed to get leaderboard: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting leaderboard: $e');
    }
  }

  static Future<Map<String, dynamic>> getMyRank() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/my-rank'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to get user rank: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user rank: $e');
    }
  }
}
