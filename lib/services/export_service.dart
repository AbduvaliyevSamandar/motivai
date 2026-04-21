import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bundles all user-owned local data into a single JSON blob for export.
class ExportService {
  static const _keys = [
    'motivai_notifs_v1',
    'motivai_notifs_enabled',
    'motivai_reminder_minutes',
    'motivai_local_schedules_v1',
    'motivai_streak_freezes',
    'motivai_streak_freeze_last_grant',
    'motivai_daily_challenge_completed',
    'motivai_daily_challenge_date',
    'motivai_daily_challenge_progress',
    'motivai_unlocked_achievements',
    'motivai_habits_v1',
    'motivai_flash_decks_v1',
    'motivai_flash_cards_v1',
    'motivai_theme_dark',
    'motivai_lang',
  ];

  /// Produce a JSON document containing all keys + version metadata.
  static Future<String> exportJson() async {
    final p = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final k in _keys) {
      final v = p.get(k);
      if (v == null) continue;
      data[k] = v is List ? v : v.toString();
    }
    final payload = {
      'app': 'MotivAI',
      'version': '2.2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Copy the JSON to clipboard and return the byte length.
  static Future<int> exportToClipboard() async {
    final json = await exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    return json.length;
  }
}
