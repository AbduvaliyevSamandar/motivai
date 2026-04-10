import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  String? _selectedDifficulty;

  List<Task> get tasks => _filteredTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTasks({
    String? category,
    String? difficulty,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _tasks = await ApiService.getTasks(
        category: category,
        difficulty: difficulty,
      );

      _filteredTasks = _tasks;
      _selectedCategory = category;
      _selectedDifficulty = difficulty;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> getTaskDetails(String taskId) async {
    try {
      return await ApiService.getTask(taskId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTasks = _tasks;

    if (_selectedCategory != null && _selectedCategory != 'All') {
      _filteredTasks = _filteredTasks
          .where((task) => task.category == _selectedCategory)
          .toList();
    }

    if (_selectedDifficulty != null && _selectedDifficulty != 'All') {
      _filteredTasks = _filteredTasks
          .where((task) => task.difficulty == _selectedDifficulty)
          .toList();
    }

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ProgressProvider extends ChangeNotifier {
  List<Progress> _userProgress = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _weeklyStats;

  List<Progress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get weeklyStats => _weeklyStats;

  Future<bool> startTask(String taskId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.startTask(taskId);

      _isLoading = false;
      await fetchUserProgress();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(String taskId, {String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.completeTask(taskId, notes: notes);

      _isLoading = false;
      await fetchUserProgress();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserProgress() async {
    try {
      _isLoading = true;
      notifyListeners();

      _userProgress = await ApiService.getUserProgress();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeeklyStats() async {
    try {
      _weeklyStats = await ApiService.getWeeklyStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardEntry? _userRank;
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  LeaderboardEntry? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaderboard() async {
    try {
      _isLoading = true;
      notifyListeners();

      _leaderboard = await ApiService.getGlobalLeaderboard();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserRank() async {
    try {
      _userRank = await ApiService.getUserRank();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class AIProvider extends ChangeNotifier {
  MotivationPlan? _motivationPlan;
  Map<String, dynamic>? _dailyInsight;
  List<MotivationPlan> _recommendations = [];
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isLoading = false;
  String? _error;

  MotivationPlan? get motivationPlan => _motivationPlan;
  Map<String, dynamic>? get dailyInsight => _dailyInsight;
  List<MotivationPlan> get recommendations => _recommendations;
  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AIProvider() {
    // Initialize with greeting
    _chatMessages = [
      {
        'sender': 'ai',
        'content': 'Salom! 👋 Men sizning motivatsiya konsultantingizman. Kundalik, haftalik yoki oylik motivatsion rejani yaratishimni xohlaysizmi?',
        'timestamp': DateTime.now(),
      }
    ];
  }

  Future<void> fetchMotivationPlan() async {
    try {
      _isLoading = true;
      notifyListeners();

      _motivationPlan = await ApiService.getMotivationPlan();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyInsight() async {
    try {
      _dailyInsight = await ApiService.getDailyInsight();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _recommendations = await ApiService.getRecommendations(count: 5);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String message) async {
    if (message.isEmpty) return;

    // Add user message
    _chatMessages.add({
      'sender': 'user',
      'content': message,
      'timestamp': DateTime.now(),
    });

    _isLoading = true;
    notifyListeners();

    try {
      // Call AI chat API with conversation history
      final aiResponse = await ApiService.chatWithAI(
        message: message,
        conversationHistory: _chatMessages
            .where((m) => m['sender'] != null)
            .map((m) => {
          'role': m['sender'] == 'user' ? 'user' : 'assistant',
          'content': m['content'],
        })
            .toList(),
      );

      if (aiResponse['success'] == true) {
        _chatMessages.add({
          'sender': 'ai',
          'content': aiResponse['message'] ?? 'Javob berish uchun muammoga duch keldi',
          'timestamp': DateTime.now(),
        });
      } else {
        _chatMessages.add({
          'sender': 'ai',
          'content': aiResponse['message'] ?? 'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.',
          'timestamp': DateTime.now(),
        });
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _chatMessages.add({
        'sender': 'ai',
        'content': 'Xatolik yuz berdi: ${e.toString()}',
        'timestamp': DateTime.now(),
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _chatMessages = [
      {
        'sender': 'ai',
        'content': 'Salom! 👋 Men sizning motivatsiya konsultantingizman. Kundalik, haftalik yoki oylik motivatsion rejani yaratishimni xohlaysizmi?',
        'timestamp': DateTime.now(),
      }
    ];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
