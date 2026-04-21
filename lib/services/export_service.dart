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

  /// Returns a small subset — just templates (habits, flashcards) — for
  /// sharing across users. Stripped of completion history.
  static Future<String> exportTemplateJson() async {
    final p = await SharedPreferences.getInstance();
    final habitsRaw = p.getString('motivai_habits_v1');
    final decksRaw = p.getString('motivai_flash_decks_v1');
    final cardsRaw = p.getString('motivai_flash_cards_v1');

    final out = <String, dynamic>{
      'app': 'MotivAI',
      'kind': 'template',
      'version': '2.2.0',
      'exportedAt': DateTime.now().toIso8601String(),
    };

    if (habitsRaw != null) {
      try {
        final habits = jsonDecode(habitsRaw) as List;
        // Strip personal completion data — keep only structural fields
        out['habits'] = habits.map((h) {
          if (h is Map) {
            return {
              'title': h['title'],
              'emoji': h['emoji'],
              'color': h['color'],
              'targetPerWeek': h['targetPerWeek'],
            };
          }
          return null;
        }).where((e) => e != null).toList();
      } catch (_) {}
    }

    if (decksRaw != null && cardsRaw != null) {
      try {
        out['flashcard_decks'] = jsonDecode(decksRaw);
        out['flashcards'] = (jsonDecode(cardsRaw) as List).map((c) {
          if (c is Map) {
            return {
              'deckId': c['deckId'],
              'front': c['front'],
              'back': c['back'],
            };
          }
          return null;
        }).where((e) => e != null).toList();
      } catch (_) {}
    }

    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// Share template via clipboard.
  static Future<int> shareTemplate() async {
    final j = await exportTemplateJson();
    await Clipboard.setData(ClipboardData(text: j));
    return j.length;
  }

  /// Merge an incoming template JSON into local storage. Returns
  /// summary of what was added.
  static Future<ImportResult> importTemplateJson(String raw) async {
    final p = await SharedPreferences.getInstance();
    int habits = 0, decks = 0, cards = 0;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map) {
        return ImportResult(error: 'Noto\'g\'ri JSON formati');
      }

      // Habits
      final hNew = (parsed['habits'] as List?) ?? [];
      if (hNew.isNotEmpty) {
        final existing = <dynamic>[];
        final raw = p.getString('motivai_habits_v1');
        if (raw != null) {
          try {
            existing.addAll(jsonDecode(raw) as List);
          } catch (_) {}
        }
        final existingTitles = existing
            .whereType<Map>()
            .map((m) => (m['title'] ?? '').toString())
            .toSet();
        for (final h in hNew) {
          if (h is! Map) continue;
          final t = (h['title'] ?? '').toString();
          if (t.isEmpty || existingTitles.contains(t)) continue;
          existing.add({
            'id': DateTime.now().microsecondsSinceEpoch.toString() +
                '_${habits}',
            'title': t,
            'emoji': h['emoji'] ?? '\u{1F331}',
            'color': h['color'] ?? 0xFF22C55E,
            'targetPerWeek': h['targetPerWeek'] ?? 5,
            'completedDates': <String>[],
            'createdAt':
                DateTime.now().toIso8601String(),
          });
          habits++;
        }
        await p.setString('motivai_habits_v1', jsonEncode(existing));
      }

      // Flashcard decks + cards
      final dNew = (parsed['flashcard_decks'] as List?) ?? [];
      final cNew = (parsed['flashcards'] as List?) ?? [];
      if (dNew.isNotEmpty || cNew.isNotEmpty) {
        final existingDecks = <dynamic>[];
        final existingCards = <dynamic>[];
        final dr = p.getString('motivai_flash_decks_v1');
        final cr = p.getString('motivai_flash_cards_v1');
        if (dr != null) {
          try {
            existingDecks.addAll(jsonDecode(dr) as List);
          } catch (_) {}
        }
        if (cr != null) {
          try {
            existingCards.addAll(jsonDecode(cr) as List);
          } catch (_) {}
        }
        final existingDeckTitles = existingDecks
            .whereType<Map>()
            .map((m) => (m['title'] ?? '').toString())
            .toSet();
        // Map old deckId -> new deckId when title was already ours
        final deckIdMap = <String, String>{};
        for (final d in dNew) {
          if (d is! Map) continue;
          final title = (d['title'] ?? '').toString();
          if (title.isEmpty) continue;
          if (existingDeckTitles.contains(title)) {
            final match = existingDecks.firstWhere(
                (m) => m is Map && m['title'] == title,
                orElse: () => null);
            if (match is Map) {
              deckIdMap[d['id']?.toString() ?? ''] =
                  match['id']?.toString() ?? '';
            }
            continue;
          }
          final newId =
              DateTime.now().microsecondsSinceEpoch.toString() +
                  '_d$decks';
          deckIdMap[d['id']?.toString() ?? ''] = newId;
          existingDecks.add({
            'id': newId,
            'title': title,
            'emoji': d['emoji'] ?? '\u{1F4D6}',
            'createdAt': DateTime.now().toIso8601String(),
          });
          decks++;
        }
        for (final c in cNew) {
          if (c is! Map) continue;
          final oldDeckId = c['deckId']?.toString() ?? '';
          final targetDeck =
              deckIdMap[oldDeckId] ?? oldDeckId;
          if (targetDeck.isEmpty) continue;
          existingCards.add({
            'id': DateTime.now().microsecondsSinceEpoch.toString() +
                '_c$cards',
            'deckId': targetDeck,
            'front': c['front'] ?? '',
            'back': c['back'] ?? '',
            'ease': 2.5,
            'interval': 0,
            'reps': 0,
            'dueAt': DateTime.now().toIso8601String(),
          });
          cards++;
        }
        await p.setString(
            'motivai_flash_decks_v1', jsonEncode(existingDecks));
        await p.setString(
            'motivai_flash_cards_v1', jsonEncode(existingCards));
      }
      return ImportResult(habits: habits, decks: decks, cards: cards);
    } catch (e) {
      return ImportResult(error: 'Xatolik: $e');
    }
  }
}

class ImportResult {
  final int habits;
  final int decks;
  final int cards;
  final String? error;
  ImportResult({this.habits = 0, this.decks = 0, this.cards = 0, this.error});
  bool get ok => error == null;
  int get totalAdded => habits + decks + cards;
}
