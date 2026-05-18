import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/strings.dart';
import 'activity_tracker.dart';
import 'notification_service.dart';
import 'user_scope.dart';

/// SmartReminder picks the user's most-active hour from history and
/// schedules ONE daily nudge at that hour. The content is randomised
/// across a small bank of motivational lines (uz/ru/en).
///
/// Lifecycle:
///   - Call [refresh] on app open and after task completion. It
///     idempotently reschedules tomorrow's nudge based on the latest
///     activity histogram.
///   - The user can disable smart reminders entirely; we then cancel
///     the slot and back off.
class SmartReminder {
  static const int _slotId = 8800042;
  static const _enabledKey = 'smart_reminder_enabled_v1';
  static const _hourOverrideKey = 'smart_reminder_hour_v1';

  /// Default fallback when we have insufficient activity samples (<10).
  static const int _defaultHour = 9;

  /// Minimum samples before we trust the histogram.
  static const int _minSamples = 10;

  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(UserScope.key(_enabledKey)) ?? true;
  }

  static Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(UserScope.key(_enabledKey), v);
    if (v) {
      await refresh();
    } else {
      await NotificationService.instance.cancel(_slotId);
    }
  }

  /// User can pin the hour manually (override the smart pick).
  /// `null` clears the override and lets the algorithm decide.
  static Future<void> setHourOverride(int? hour) async {
    final p = await SharedPreferences.getInstance();
    if (hour == null) {
      await p.remove(UserScope.key(_hourOverrideKey));
    } else {
      await p.setInt(UserScope.key(_hourOverrideKey), hour.clamp(0, 23));
    }
    await refresh();
  }

  static Future<int?> hourOverride() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(UserScope.key(_hourOverrideKey));
    return v;
  }

  /// Returns the hour we'd schedule the next nudge at. Public so the
  /// settings screen can show "Bugun {hour}:00 da yuboriladi".
  static Future<int> bestHour() async {
    final override = await hourOverride();
    if (override != null) return override;
    final hist = await ActivityTracker.hourlyHistogram();
    final samples = await ActivityTracker.sampleCount();
    if (samples < _minSamples) return _defaultHour;
    int best = 0;
    int bestVal = -1;
    for (var h = 0; h < 24; h++) {
      // Don't nudge at 1 AM even if user is night-active — keep daytime.
      if (h < 7 || h > 22) continue;
      if (hist[h] > bestVal) {
        bestVal = hist[h];
        best = h;
      }
    }
    return best == 0 ? _defaultHour : best;
  }

  /// Pick a random nudge line (translated). Kept short — notification
  /// previews are typically truncated past ~80 chars on the lock screen.
  static (String title, String body) pickNudge() {
    final lines = <(String, String, String, String, String, String)>[
      // (titleUz, titleRu, titleEn, bodyUz, bodyRu, bodyEn)
      (
        '🎯 Bugungi maqsad',
        '🎯 Цель дня',
        "🎯 Today's goal",
        '1 ta vazifa — 1 qadam yaqinroq.',
        '1 задача — 1 шаг ближе.',
        'One task = one step closer.',
      ),
      (
        '🔥 Streak xavf ostida',
        '🔥 Streak под угрозой',
        '🔥 Streak at risk',
        'Bugun ham 1 vazifa qilsangiz — streak saqlanadi.',
        'Сегодня хотя бы 1 задача — streak сохранён.',
        'One task today keeps your streak alive.',
      ),
      (
        '✨ MIT vaqti',
        '✨ MIT — самое важное',
        '✨ MIT time',
        'Bugun eng muhim 3 ishni tanlang va boshlang.',
        'Выберите 3 главные задачи и начните.',
        'Pick the 3 most important tasks and start.',
      ),
      (
        '⚡ Kichik qadam',
        '⚡ Маленький шаг',
        '⚡ Tiny step',
        '5 daqiqa fokus — keyin to\'xtab tursangiz ham bo\'ladi.',
        '5 минут фокуса — потом можно остановиться.',
        '5 minutes of focus — you can stop after.',
      ),
      (
        '🌱 Sayohatingiz davom etadi',
        '🌱 Путешествие продолжается',
        '🌱 Your journey continues',
        'Daraxt o\'sishi uchun — bugungi 1 vazifa.',
        'Дереву нужно — 1 сегодняшняя задача.',
        'Your tree needs — one task today.',
      ),
    ];
    final pick = lines[Random().nextInt(lines.length)];
    final title = S.tr(pick.$1, pick.$2, pick.$3);
    final body = S.tr(pick.$4, pick.$5, pick.$6);
    return (title, body);
  }

  /// Schedule (or reschedule) tomorrow's nudge at the computed hour.
  /// Idempotent: cancels prior slot before scheduling.
  static Future<void> refresh() async {
    if (!await isEnabled()) return;
    await NotificationService.instance.cancel(_slotId);
    final hour = await bestHour();
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, hour, 0);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    final (title, body) = pickNudge();
    await NotificationService.instance.scheduleAt(
      id: _slotId,
      title: title,
      body: body,
      at: when,
      payload: 'smart_reminder',
    );
  }
}
