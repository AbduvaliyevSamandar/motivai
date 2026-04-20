import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/local_schedules.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'notification_provider.dart';

class TaskProvider extends ChangeNotifier {
  final _api = Api();

  List<Task>    _planTasks   = [];
  List<LbEntry> _globalLb    = [];
  List<LbEntry> _weeklyLb    = [];
  Map<String, dynamic>? _myRank;
  Map<String, dynamic>? _insights;
  Map<String, dynamic>? _planStats;
  List<Achievement> _achievements = [];

  bool   _loading    = false;
  bool   _completing = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────
  List<Task>    get daily       => _planTasks.where((t) => !t.isCompleted).toList();
  List<Task>    get recommended => _planTasks.where((t) => !t.isCompleted).take(5).toList();
  List<LbEntry> get globalLb    => _globalLb;
  List<LbEntry> get weeklyLb    => _weeklyLb;
  Map<String, dynamic>? get myRank   => _myRank;
  Map<String, dynamic>? get insights => _insights;
  Map<String, dynamic>? get planStats => _planStats;
  List<Achievement> get achievements => _achievements;
  bool   get isLoading    => _loading;
  bool   get isCompleting => _completing;
  String? get error       => _error;

  int    get completedToday => _planTasks.where((t) => t.isCompleted).length;
  int    get totalToday     => _planTasks.length;
  double get dailyProgress  =>
      _planTasks.isEmpty ? 0 : completedToday / _planTasks.length;

  void updateToken(String? _) {}

  // ── LOAD ALL ──────────────────────────────────────────
  Future<void> loadAll() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    await Future.wait([
      _loadPlans(),
      _loadLeaderboard(),
    ]);
    _loading = false;
    notifyListeners();
  }

  // ── LOAD PLANS (backend plans tizimidan tasklar olish) ──
  Future<void> _loadPlans() async {
    try {
      final res = await _api.get('${K.plans}?is_active=true');
      // Backend: {"success":true, "data": {"plans": [...]}}
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final plans = data['plans'] as List? ?? [];

      _planTasks = [];
      // Load local schedules once
      final localSchedules = await LocalSchedules.getAll();

      for (final plan in plans) {
        final planId = (plan['_id'] ?? plan['id'] ?? '').toString();
        final planTitle = plan['title']?.toString() ?? '';
        final tasks = plan['tasks'] as List? ?? [];
        for (final t in tasks) {
          final taskMap = Map<String, dynamic>.from(t as Map);
          taskMap['plan_id'] = planId;
          taskMap['plan_title'] = planTitle;
          taskMap['_id'] = taskMap['id'] ?? '';
          final taskId = (taskMap['id'] ?? '').toString();
          final title = (taskMap['title'] ?? '').toString();

          // Merge local schedule if exists (by id, or pending:title)
          var local = localSchedules[taskId];
          local ??= localSchedules['pending:$title'];
          if (local != null) {
            taskMap['scheduled_at'] = local.at.toIso8601String();
            taskMap['reminder_minutes'] = local.remind;
            // Promote pending to id-keyed for next time
            if (taskId.isNotEmpty) {
              await LocalSchedules.promotePending(
                  title: title, taskId: taskId);
            }
          } else if (taskMap['scheduled_time'] is String) {
            // Backend gives HH:MM — compose a DateTime for today/tomorrow
            final hm = (taskMap['scheduled_time'] as String).split(':');
            if (hm.length == 2) {
              final hh = int.tryParse(hm[0]) ?? 0;
              final mm = int.tryParse(hm[1]) ?? 0;
              final now = DateTime.now();
              var at = DateTime(now.year, now.month, now.day, hh, mm);
              if (at.isBefore(now)) {
                at = at.add(const Duration(days: 1));
              }
              taskMap['scheduled_at'] = at.toIso8601String();
            }
          }

          _planTasks.add(Task.fromJson(taskMap));
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── LEADERBOARD ───────────────────────────────────────
  Future<void> _loadLeaderboard() async {
    try {
      // Backend: GET /leaderboard?period=weekly
      final gRes = await _api.get('${K.leaderboard}?period=alltime&limit=50');
      final gData = gRes['data'] as Map<String, dynamic>? ?? gRes;
      _globalLb = _parseLb(gData);

      final wRes = await _api.get('${K.leaderboard}?period=weekly&limit=50');
      final wData = wRes['data'] as Map<String, dynamic>? ?? wRes;
      _weeklyLb = _parseLb(wData);

      // Backend: GET /leaderboard/my-rank
      final rRes = await _api.get(K.myRank);
      final rData = rRes['data'] as Map<String, dynamic>? ?? rRes;
      _myRank = rData.cast<String, dynamic>();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshLeaderboard() async {
    await _loadLeaderboard();
  }

  // ── ACHIEVEMENTS (user badges orqali) ─────────────────
  Future<void> loadAchievements() async {
    try {
      // Backend /ai/achievements yo'q, badges user profilida
      // Plan stats dan olamiz
      final res = await _api.get(K.planStats);
      final data = res['data'] as Map<String, dynamic>? ?? res;
      _planStats = data;
      // Achievements bo'sh — backendda alohida endpoint yo'q
      _achievements = [];
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadInsights() async {
    try {
      final res = await _api.get(K.insights);
      // Backend: {"success":true, "data": {...}}
      final data = res['data'] as Map<String, dynamic>? ?? res;
      _insights = data.cast<String, dynamic>();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── COMPLETE TASK (plan ichidagi task) ─────────────────
  Future<Map<String, dynamic>?> complete(
    String taskId, {
    String? planId,
    int?    timeSpent,
    String? notes,
    int?    rating,
  }) async {
    _completing = true;
    _error      = null;
    notifyListeners();
    try {
      // Plan ID topish — taskga biriktirilgan
      final actualPlanId = planId ?? _findPlanId(taskId);
      if (actualPlanId == null) {
        throw ApiError('Ushbu vazifa uchun plan topilmadi');
      }

      // Backend: POST /plans/{plan_id}/complete-task
      final res = await _api.post('${K.plans}/$actualPlanId/complete-task', {
        'task_id': taskId,
        if (timeSpent != null) 'study_minutes': timeSpent,
      });

      final data = res['data'] as Map<String, dynamic>? ?? res;
      _markDone(taskId);
      _completing = false;
      notifyListeners();
      return data.cast<String, dynamic>();
    } catch (e) {
      _error      = e.toString();
      _completing = false;
      notifyListeners();
      return null;
    }
  }

  String? _findPlanId(String taskId) {
    for (final task in _planTasks) {
      if (task.id == taskId && task.planId != null) {
        return task.planId;
      }
    }
    return null;
  }

  void _markDone(String id) {
    _planTasks = _planTasks
        .map((t) => t.id == id
            ? t.copyWith(isCompleted: true, completedAt: DateTime.now())
            : t)
        .toList();
  }

  // ── HELPERS ───────────────────────────────────────────
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

  // ── NOTIFICATIONS SYNC ────────────────────────────────
  /// After loading tasks, schedule reminders and fire overdue notifs.
  /// Called from MainShell after loadAll completes and periodically.
  Future<void> syncNotifications(NotificationProvider notifs) async {
    if (!notifs.enabled) return;
    for (final t in _planTasks) {
      if (t.isCompleted) {
        await notifs.cancelTaskReminder(t.id);
        continue;
      }
      if (!t.hasSchedule) continue;

      // Overdue check
      if (t.isOverdue) {
        await notifs.fireOverdue(taskId: t.id, taskTitle: t.title);
        await notifs.cancelTaskReminder(t.id);
        continue;
      }

      // Schedule reminder (idempotent — plugin replaces by id)
      await notifs.scheduleTaskReminder(
        taskId: t.id,
        taskTitle: t.title,
        scheduledAt: t.scheduledAt!,
        reminderMinutes: t.reminderMinutes,
      );

      // In-app soon alert (only if within reminder window and not flagged yet)
      if (t.isUpcomingSoon) {
        final already = notifs.feed.any((n) =>
            n.type == AppNotifType.reminder && n.taskId == t.id);
        if (!already) {
          await notifs.fireUpcomingInApp(
            taskId: t.id,
            taskTitle: t.title,
            minutesUntil: t.timeUntil?.inMinutes ?? 0,
          );
        }
      }
    }
  }
}
