import 'package:flutter/material.dart';
import '../services/api.dart';
import '../config/constants.dart';
import '../models/models.dart';

class TaskProvider extends ChangeNotifier {
  final _api = Api();

  List<Task>    _daily     = [];
  List<Task>    _recommended = [];
  List<LbEntry> _globalLb  = [];
  List<LbEntry> _weeklyLb  = [];
  Map<String, dynamic>? _myRank;
  Map<String, dynamic>? _insights;
  List<Achievement> _achievements = [];

  bool   _loading    = false;
  bool   _completing = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────
  List<Task>    get daily       => _daily;
  List<Task>    get recommended => _recommended;
  List<LbEntry> get globalLb    => _globalLb;
  List<LbEntry> get weeklyLb    => _weeklyLb;
  Map<String, dynamic>? get myRank   => _myRank;
  Map<String, dynamic>? get insights => _insights;
  List<Achievement> get achievements => _achievements;
  bool   get isLoading    => _loading;
  bool   get isCompleting => _completing;
  String? get error       => _error;

  int    get completedToday => _daily.where((t) => t.isCompleted).length;
  int    get totalToday     => _daily.length;
  double get dailyProgress  =>
      _daily.isEmpty ? 0 : completedToday / _daily.length;

  void updateToken(String? _) {}

  // ── LOAD ALL ──────────────────────────────────────────
  Future<void> loadAll() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    await Future.wait([
      _loadDaily(),
      _loadRecommended(),
      _loadLeaderboard(),
    ]);
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadDaily() async {
    try {
      final d = await _api.get(K.daily);
      _daily = _parseTasks(d);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadRecommended() async {
    try {
      final d = await _api.get(K.recommended);
      _recommended = _parseTasks(d);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final g = await _api.get(K.globalLb);
      _globalLb = _parseLb(g);

      final w = await _api.get(K.weeklyLb);
      _weeklyLb = _parseLb(w);

      final r = await _api.get(K.myRank);
      _myRank = (r as Map).cast<String, dynamic>();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshLeaderboard() async {
    await _loadLeaderboard();
  }

  Future<void> loadAchievements() async {
    try {
      final d = await _api.get(K.achievements);
      final list = d['achievements'] as List? ?? [];
      _achievements = list
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadInsights() async {
    try {
      final d = await _api.get(K.insights);
      _insights = (d as Map).cast<String, dynamic>();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── COMPLETE TASK ─────────────────────────────────────
  Future<Map<String, dynamic>?> complete(
    String taskId, {
    int?    timeSpent,
    String? notes,
    int?    rating,
  }) async {
    _completing = true;
    _error      = null;
    notifyListeners();
    try {
      final res = await _api.post(K.complete, {
        'task_id': taskId,
        if (timeSpent != null) 'time_spent_minutes': timeSpent,
        if (notes != null)     'notes':              notes,
        if (rating != null)    'rating':             rating,
      });
      _markDone(taskId);
      _completing = false;
      notifyListeners();
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      _error      = e.toString();
      _completing = false;
      notifyListeners();
      return null;
    }
  }

  void _markDone(String id) {
    _daily = _daily
        .map((t) => t.id == id
            ? t.copyWith(isCompleted: true, completedAt: DateTime.now())
            : t)
        .toList();
    _recommended = _recommended.where((t) => t.id != id).toList();
  }

  // ── HELPERS ───────────────────────────────────────────
  List<Task> _parseTasks(dynamic d) {
    final list = (d is Map ? d['tasks'] : d) as List? ?? [];
    return list
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  List<LbEntry> _parseLb(dynamic d) {
    final list = (d is Map ? d['leaderboard'] : d) as List? ?? [];
    return list
        .map((e) => LbEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
