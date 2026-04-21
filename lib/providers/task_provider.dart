import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/local_schedules.dart';
import '../services/pinned_storage.dart';
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
  /// All tasks (active + completed)
  List<Task>    get all         => List.unmodifiable(_planTasks);
  Set<String> _pinned = {};
  Set<String> get pinned => _pinned;
  bool isPinned(String id) => _pinned.contains(id);

  Future<void> togglePin(String id) async {
    await PinnedStorage.toggle(id);
    _pinned = await PinnedStorage.load();
    notifyListeners();
  }

  /// Only non-completed — pinned items sorted first
  List<Task>    get active      {
    final list = _planTasks.where((t) => !t.isCompleted).toList();
    list.sort((a, b) {
      final ap = _pinned.contains(a.id);
      final bp = _pinned.contains(b.id);
      if (ap != bp) return ap ? -1 : 1;
      return 0;
    });
    return list;
  }
  /// Only completed (most recent first)
  List<Task>    get completed   {
    final list = _planTasks.where((t) => t.isCompleted).toList();
    list.sort((a, b) {
      final ad = a.completedAt ?? DateTime(2000);
      final bd = b.completedAt ?? DateTime(2000);
      return bd.compareTo(ad);
    });
    return list;
  }
  /// Deprecated — kept for backward compat; returns active for now
  List<Task>    get daily       => active;
  List<Task>    get recommended => const <Task>[];
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
    _pinned = await PinnedStorage.load();
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
      debugPrint('📥 loadPlans response runtimeType: ${res.runtimeType}');
      // Backend: {"success":true, "data": {"plans": [...]}}
      final data = res is Map
          ? (res['data'] is Map
              ? (res['data'] as Map).cast<String, dynamic>()
              : res.cast<String, dynamic>())
          : <String, dynamic>{};
      final plans = data['plans'] is List
          ? (data['plans'] as List)
          : const [];
      debugPrint('📥 loadPlans — ${plans.length} plans fetched');

      final rebuilt = <Task>[];
      final localSchedules = await LocalSchedules.getAll();

      for (final plan in plans) {
        if (plan is! Map) continue;
        final planMap = plan.cast<String, dynamic>();
        final planId = (planMap['_id'] ?? planMap['id'] ?? '').toString();
        final planTitle = (planMap['title'] ?? '').toString();
        final tasks = planMap['tasks'] is List
            ? (planMap['tasks'] as List)
            : const [];
        for (final t in tasks) {
          if (t is! Map) continue;
          try {
            final taskMap = (t).cast<String, dynamic>();
            final mutable = Map<String, dynamic>.from(taskMap);
            mutable['plan_id'] = planId;
            mutable['plan_title'] = planTitle;
            mutable['_id'] = mutable['id'] ?? '';
            final taskId = (mutable['id'] ?? '').toString();
            final title = (mutable['title'] ?? '').toString();

            var local = localSchedules[taskId];
            local ??= localSchedules['pending:$title'];
            if (local != null) {
              mutable['scheduled_at'] = local.at.toIso8601String();
              mutable['reminder_minutes'] = local.remind;
              if (taskId.isNotEmpty) {
                await LocalSchedules.promotePending(
                    title: title, taskId: taskId);
              }
            } else if (mutable['scheduled_time'] is String) {
              final hm = (mutable['scheduled_time'] as String).split(':');
              if (hm.length == 2) {
                final hh = int.tryParse(hm[0]) ?? 0;
                final mm = int.tryParse(hm[1]) ?? 0;
                final now = DateTime.now();
                var at = DateTime(now.year, now.month, now.day, hh, mm);
                if (at.isBefore(now)) {
                  at = at.add(const Duration(days: 1));
                }
                mutable['scheduled_at'] = at.toIso8601String();
              }
            }

            rebuilt.add(Task.fromJson(mutable));
          } catch (e) {
            debugPrint('⚠️ task parse error: $e (task: $t)');
          }
        }
      }

      _planTasks = rebuilt;
      debugPrint('✅ loadPlans done — ${_planTasks.length} tasks');
    } catch (e) {
      debugPrint('❌ loadPlans error: $e');
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

  // ── CREATE TASK ───────────────────────────────────────
  /// Unified task creation. Returns true on success. Does optimistic UI
  /// update — newly created task appears instantly, even before reload.
  Future<bool> createTask({
    required String title,
    String description = '',
    String category = 'study',
    String difficulty = 'medium',
    int durationMinutes = 30,
    int xpReward = 50,
    DateTime? scheduledAt,
    int reminderMinutes = 15,
  }) async {
    _error = null;
    try {
      final taskBody = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'duration': durationMinutes,
        'xp_reward': xpReward,
      };
      if (scheduledAt != null) {
        final hh = scheduledAt.hour.toString().padLeft(2, '0');
        final mm = scheduledAt.minute.toString().padLeft(2, '0');
        taskBody['scheduled_time'] = '$hh:$mm';
      }

      final planBody = <String, dynamic>{
        'title': title,
        'description': description,
        'goal': title,
        'category': category,
        'duration': 1,
        'tasks': [taskBody],
        'milestones': [],
        'reminder_enabled': reminderMinutes > 0,
        'visibility': 'private',
      };

      final res = await _api.post(K.plans, planBody);

      // Parse response — extract new plan + task ids for optimistic insert
      String? planId;
      String? taskId;
      try {
        final data = res is Map ? res['data'] as Map? : null;
        final plan = data?['plan'];
        if (plan is Map) {
          planId = (plan['_id'] ?? plan['id'])?.toString();
          final tasks = plan['tasks'] as List?;
          if (tasks != null && tasks.isNotEmpty) {
            taskId = (tasks.first['id'] ?? tasks.first['_id'])?.toString();
          }
        }
      } catch (_) {}

      // Save scheduling locally if provided
      if (scheduledAt != null && taskId != null && taskId.isNotEmpty) {
        await LocalSchedules.saveById(
          taskId: taskId,
          scheduledAt: scheduledAt,
          reminderMinutes: reminderMinutes,
        );
      } else if (scheduledAt != null) {
        await LocalSchedules.savePending(
          title: title,
          scheduledAt: scheduledAt,
          reminderMinutes: reminderMinutes,
        );
      }

      // Optimistic insert so UI updates IMMEDIATELY (even before reload)
      if (taskId != null && taskId.isNotEmpty) {
        _planTasks.insert(
          0,
          Task(
            id: taskId,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            points: xpReward,
            durationMinutes: durationMinutes,
            planId: planId,
            planTitle: title,
            scheduledAt: scheduledAt,
            reminderMinutes: reminderMinutes,
          ),
        );
        notifyListeners();
        debugPrint('✅ Optimistic insert — new task $taskId added (total: ${_planTasks.length})');
      } else {
        debugPrint('⚠️ No taskId extracted from response — relying on reload');
      }

      // Await reload so the caller sees the final state
      await _loadPlans();
      debugPrint('♻️ Reload complete — total tasks: ${_planTasks.length}');
      return true;
    } catch (e) {
      debugPrint('❌ createTask error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── BULK CREATE (from AI chat) ────────────────────────
  /// Creates a single plan containing multiple AI-suggested tasks.
  /// Returns the created plan id on success, null on failure.
  /// Does optimistic insert so all tasks appear instantly.
  Future<String?> addSuggestions({
    required List<TaskSuggestion> suggestions,
    String planTitle = 'AI taklif etgan vazifalar',
    String goal = 'AI tavsiyalarini bajarish',
  }) async {
    if (suggestions.isEmpty) return null;
    _error = null;
    try {
      final taskBodies = suggestions
          .map((s) => {
                'title': s.title,
                'description': s.description,
                'category': s.category,
                'difficulty': s.difficulty,
                'duration': s.durationMinutes,
                'xp_reward': s.estimatedPoints,
              })
          .toList();

      final planBody = <String, dynamic>{
        'title': planTitle,
        'description': 'AI chat orqali qo\'shilgan',
        'goal': goal,
        'category': 'study',
        'duration': 1,
        'tasks': taskBodies,
        'milestones': [],
        'reminder_enabled': true,
        'visibility': 'private',
      };

      final res = await _api.post(K.plans, planBody);

      String? planId;
      final List<Task> newTasks = [];
      try {
        final data = res is Map ? res['data'] as Map? : null;
        final plan = data?['plan'];
        if (plan is Map) {
          planId = (plan['_id'] ?? plan['id'])?.toString();
          final tasks = plan['tasks'] as List?;
          if (tasks != null) {
            for (var i = 0; i < tasks.length; i++) {
              final t = tasks[i] as Map<String, dynamic>;
              final id = (t['id'] ?? t['_id'])?.toString() ?? '';
              final src = i < suggestions.length ? suggestions[i] : null;
              newTasks.add(Task(
                id: id,
                title: t['title']?.toString() ?? src?.title ?? '',
                description:
                    t['description']?.toString() ?? src?.description ?? '',
                category: t['category']?.toString() ?? 'study',
                difficulty: t['difficulty']?.toString() ?? 'medium',
                points:
                    (t['xp_reward'] ?? src?.estimatedPoints ?? 30) as int,
                durationMinutes:
                    (t['duration_minutes'] ?? src?.durationMinutes ?? 30)
                        as int,
                planId: planId,
                planTitle: planTitle,
                isFromChat: true,
              ));
            }
          }
        }
      } catch (_) {}

      // Optimistic insert — put all new tasks at top
      if (newTasks.isNotEmpty) {
        _planTasks.insertAll(0, newTasks);
        notifyListeners();
      }

      // Await reload to ensure final state is synced
      await _loadPlans();
      return planId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── DELETE TASK ────────────────────────────────────────
  /// Since each user-added task lives in its own plan, delete = delete plan.
  /// For multi-task plans (AI-added bulk), we keep the plan and only drop the
  /// task locally + via PUT plan with updated tasks list.
  Future<bool> deleteTask(String taskId, {String? planId}) async {
    _error = null;
    try {
      final pid = planId ?? _findPlanId(taskId);
      if (pid == null) {
        _error = 'Plan topilmadi';
        notifyListeners();
        return false;
      }
      final tasksInSamePlan =
          _planTasks.where((t) => t.planId == pid).length;

      if (tasksInSamePlan <= 1) {
        // Single-task plan → delete the whole plan
        await _api.delete('${K.plans}/$pid');
      } else {
        // Multi-task plan → rebuild tasks list without this one via PUT
        final remaining = _planTasks
            .where((t) => t.planId == pid && t.id != taskId)
            .map((t) => {
                  'id': t.id,
                  'title': t.title,
                  'description': t.description,
                  'category': t.category,
                  'difficulty': t.difficulty,
                  'duration': t.durationMinutes,
                  'xp_reward': t.points,
                  'is_completed': t.isCompleted,
                })
            .toList();
        await _api.put('${K.plans}/$pid', {'tasks': remaining});
      }
      _planTasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE TASK (edit) ─────────────────────────────────
  /// Update via PUT /plans/{plan_id}. Only fields we own locally (plan title /
  /// description / tasks list) are sent. Schedule + reminder stay client-side.
  Future<bool> updateTask({
    required String taskId,
    String? planId,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? durationMinutes,
    int? xpReward,
  }) async {
    _error = null;
    try {
      final pid = planId ?? _findPlanId(taskId);
      if (pid == null) {
        _error = 'Plan topilmadi';
        notifyListeners();
        return false;
      }
      // Rebuild plan's tasks list with patched task
      final updatedTasks = _planTasks
          .where((t) => t.planId == pid)
          .map((t) {
        if (t.id != taskId) {
          return {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'category': t.category,
            'difficulty': t.difficulty,
            'duration': t.durationMinutes,
            'xp_reward': t.points,
            'is_completed': t.isCompleted,
          };
        }
        return {
          'id': t.id,
          'title': title ?? t.title,
          'description': description ?? t.description,
          'category': category ?? t.category,
          'difficulty': difficulty ?? t.difficulty,
          'duration': durationMinutes ?? t.durationMinutes,
          'xp_reward': xpReward ?? t.points,
          'is_completed': t.isCompleted,
        };
      }).toList();

      final planPatch = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        'tasks': updatedTasks,
      };
      await _api.put('${K.plans}/$pid', planPatch);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
