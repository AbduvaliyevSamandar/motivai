import 'package:shared_preferences/shared_preferences.dart';

/// One-shot migration: when the app starts on a build that introduces
/// per-user storage scoping, delete every legacy global key from prior
/// versions so a fresh user can't see cached data from another account.
///
/// We intentionally KEEP the device-level prefs (theme, language, sound
/// pack, haptic level, onboarding flag, notif enabled, reminder minutes)
/// so the experience doesn't reset.
class LegacyWipe {
  static const _ranKey = 'motivai_legacy_wipe_v3';

  static const _legacyKeys = <String>[
    // Per-user data that was previously global
    'motivai_coins',
    'motivai_journey_v1',
    'motivai_morning_ritual_v1',
    'motivai_rituals_v1',
    'motivai_friend_challenges_v1',
    'motivai_friends_v1',
    'motivai_my_invite_code',
    'motivai_habits_v1',
    'motivai_flash_decks_v1',
    'motivai_flash_cards_v1',
    'motivai_task_notes_v1',
    'motivai_pinned_tasks_v1',
    'motivai_local_schedules_v1',
    'motivai_unlocked_achievements',
    'motivai_custom_categories_v1',
    'motivai_action_queue_v1',
    'motivai_user_goal',
    'motivai_user_goal_custom',
    'motivai_streak_freezes',
    'motivai_streak_freeze_last_grant',
    'motivai_daily_challenge_completed',
    'motivai_daily_challenge_date',
    'motivai_daily_challenge_progress',
    'motivai_notifs_v1',
    'motivai_avatar_local',
    'chat_history',
  ];

  static Future<void> run() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_ranKey) == true) return;
    for (final k in _legacyKeys) {
      await p.remove(k);
    }
    await p.setBool(_ranKey, true);
  }
}
