import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const _storageKey = 'motivai_notifs_v1';
  static const _enabledKey = 'motivai_notifs_enabled';
  static const _reminderKey = 'motivai_reminder_minutes';
  static const _maxFeed = 100;

  final List<AppNotif> _feed = [];
  bool _enabled = true;
  int _defaultReminderMinutes = 15;

  List<AppNotif> get feed => List.unmodifiable(_feed);
  int get unreadCount => _feed.where((n) => !n.read).length;
  bool get enabled => _enabled;
  int get defaultReminderMinutes => _defaultReminderMinutes;

  NotificationProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _enabled = p.getBool(_enabledKey) ?? true;
      _defaultReminderMinutes = p.getInt(_reminderKey) ?? 15;
      NotificationService.instance.enabled = _enabled;

      final raw = p.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _feed
          ..clear()
          ..addAll(list
              .map((e) => AppNotif.fromJson(e as Map<String, dynamic>))
              .toList());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      final trimmed = _feed.take(_maxFeed).toList();
      await p.setString(
        _storageKey,
        jsonEncode(trimmed.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    NotificationService.instance.enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, v);
    if (!v) {
      await NotificationService.instance.cancelAll();
    }
    notifyListeners();
  }

  Future<void> setDefaultReminderMinutes(int v) async {
    _defaultReminderMinutes = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_reminderKey, v);
    notifyListeners();
  }

  void add(AppNotif n) {
    _feed.insert(0, n);
    if (_feed.length > _maxFeed) {
      _feed.removeRange(_maxFeed, _feed.length);
    }
    _save();
    notifyListeners();
  }

  void markRead(String id) {
    final i = _feed.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _feed[i].read = true;
    _save();
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _feed) {
      n.read = true;
    }
    _save();
    notifyListeners();
  }

  void remove(String id) {
    _feed.removeWhere((n) => n.id == id);
    _save();
    notifyListeners();
  }

  void clear() {
    _feed.clear();
    _save();
    notifyListeners();
  }

  // ─── Task-specific helpers ─────────────────────────────
  /// Schedule reminder + add optimistic feed entry
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledAt,
    required int reminderMinutes,
  }) async {
    if (!_enabled) return;
    final remindAt =
        scheduledAt.subtract(Duration(minutes: reminderMinutes));
    if (remindAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleAt(
        id: NotificationService.taskReminderId(taskId),
        title: 'Eslatma: $taskTitle',
        body: '$reminderMinutes daqiqadan keyin boshlanadi',
        at: remindAt,
        payload: taskId,
      );
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await NotificationService.instance
        .cancel(NotificationService.taskReminderId(taskId));
    await NotificationService.instance
        .cancel(NotificationService.taskOverdueId(taskId));
  }

  /// Fire overdue notification + add to feed.
  Future<void> fireOverdue({
    required String taskId,
    required String taskTitle,
  }) async {
    if (!_enabled) return;
    if (_feed.any(
        (n) => n.type == AppNotifType.overdue && n.taskId == taskId)) {
      return; // already notified
    }
    await NotificationService.instance.show(
      id: NotificationService.taskOverdueId(taskId),
      title: "Vazifa o'tkazib yuborildi",
      body: taskTitle,
      payload: taskId,
    );
    add(AppNotif(
      id: 'o_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotifType.overdue,
      title: "Vazifa o'tkazib yuborildi",
      body: taskTitle,
      at: DateTime.now(),
      taskId: taskId,
    ));
  }

  Future<void> fireUpcomingInApp({
    required String taskId,
    required String taskTitle,
    required int minutesUntil,
  }) async {
    if (!_enabled) return;
    add(AppNotif(
      id: 'u_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotifType.reminder,
      title: 'Yaqinlashmoqda: $taskTitle',
      body: '$minutesUntil daqiqadan keyin boshlanadi',
      at: DateTime.now(),
      taskId: taskId,
    ));
  }

  void addAchievement(String title, String body) {
    add(AppNotif(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotifType.achievement,
      title: title,
      body: body,
      at: DateTime.now(),
    ));
  }
}
