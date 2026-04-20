import 'package:flutter/material.dart';
import '../config/theme.dart';

// ═══════════════════════════════════════════════════════
//  TASK MODEL
// ═══════════════════════════════════════════════════════
class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int    points;
  final int    durationMinutes;
  final List<String> tags;
  final bool   isCompleted;
  final bool   isGlobalChallenge;
  final bool   isFromChat;
  final DateTime? completedAt;
  final String? planId;
  final String? planTitle;
  final DateTime? scheduledAt;    // When task should happen
  final int reminderMinutes;      // How many minutes before to remind (0 = no reminder)

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.durationMinutes,
    this.tags              = const [],
    this.isCompleted       = false,
    this.isGlobalChallenge = false,
    this.isFromChat        = false,
    this.completedAt,
    this.planId,
    this.planTitle,
    this.scheduledAt,
    this.reminderMinutes   = 15,
  });

  String get emoji => _emojis[category] ?? '📌';
  Color  get color => C.cat[category] ?? C.primary;

  // Time helpers
  bool get hasSchedule => scheduledAt != null;
  bool get isOverdue =>
      scheduledAt != null &&
      !isCompleted &&
      DateTime.now().isAfter(scheduledAt!);
  bool get isUpcomingSoon {
    if (scheduledAt == null || isCompleted) return false;
    final diff = scheduledAt!.difference(DateTime.now());
    return diff.inMinutes > 0 && diff.inMinutes <= reminderMinutes;
  }

  Duration? get timeUntil =>
      scheduledAt?.difference(DateTime.now());

  String get timeLabel {
    if (scheduledAt == null) return '';
    final now = DateTime.now();
    final s = scheduledAt!;
    final sameDay = now.year == s.year && now.month == s.month && now.day == s.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = tomorrow.year == s.year &&
        tomorrow.month == s.month &&
        tomorrow.day == s.day;
    final hh = s.hour.toString().padLeft(2, '0');
    final mm = s.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    if (isTomorrow) return 'Erta $hh:$mm';
    return '${s.day}/${s.month} $hh:$mm';
  }

  String get diffLabel => const {
    'easy':   'Oson',
    'medium': "O'rta",
    'hard':   'Qiyin',
    'expert': 'Expert',
  }[difficulty] ?? difficulty;

  String get diffEmoji => const {
    'easy': '🟢', 'medium': '🟡', 'hard': '🟠', 'expert': '🔴',
  }[difficulty] ?? '⚪';

  static const _emojis = {
    'study': '📚', 'exercise': '💪', 'reading': '📖',
    'meditation': '🧘', 'social': '👥', 'creative': '🎨',
    'productivity': '⚡', 'challenge': '🏆',
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id:                j['_id']               ?? j['id']  ?? '',
    title:             j['title']             ?? '',
    description:       j['description']       ?? '',
    category:          j['category']          ?? 'study',
    difficulty:        j['difficulty']        ?? 'easy',
    points:            (j['xp_reward'] ?? j['points_reward'] ?? j['points'] ?? 10) as int,
    durationMinutes:   (j['duration_minutes'] ?? 30) as int,
    tags:              List<String>.from(j['tags'] ?? []),
    isCompleted:       j['is_completed']      ?? false,
    isGlobalChallenge: j['is_global_challenge'] ?? false,
    isFromChat:        j['is_from_chat']      ?? false,
    completedAt: j['completed_at'] != null
        ? DateTime.tryParse(j['completed_at'].toString())
        : null,
    planId:    j['plan_id']?.toString(),
    planTitle: j['plan_title']?.toString(),
    scheduledAt: j['scheduled_at'] != null
        ? DateTime.tryParse(j['scheduled_at'].toString())
        : null,
    reminderMinutes: (j['reminder_minutes'] ?? 15) as int,
  );

  Task copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? scheduledAt,
    int? reminderMinutes,
  }) => Task(
    id: id, title: title, description: description,
    category: category, difficulty: difficulty,
    points: points, durationMinutes: durationMinutes,
    tags: tags, isGlobalChallenge: isGlobalChallenge,
    isFromChat: isFromChat,
    isCompleted:  isCompleted  ?? this.isCompleted,
    completedAt:  completedAt  ?? this.completedAt,
    planId: planId, planTitle: planTitle,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
  );
}

// ═══════════════════════════════════════════════════════
//  APP NOTIFICATION (in-app notification feed)
// ═══════════════════════════════════════════════════════
enum AppNotifType { reminder, overdue, achievement, info }

class AppNotif {
  final String id;
  final AppNotifType type;
  final String title;
  final String body;
  final DateTime at;
  final String? taskId;
  bool read;

  AppNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    this.taskId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'at': at.toIso8601String(),
    'taskId': taskId,
    'read': read,
  };

  factory AppNotif.fromJson(Map<String, dynamic> j) => AppNotif(
    id: j['id'] ?? '',
    type: AppNotifType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => AppNotifType.info,
    ),
    title: j['title'] ?? '',
    body: j['body'] ?? '',
    at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
    taskId: j['taskId'],
    read: j['read'] ?? false,
  );
}

// ═══════════════════════════════════════════════════════
//  LEADERBOARD ENTRY
// ═══════════════════════════════════════════════════════
class LbEntry {
  final String id;
  final String fullName;
  final String username;
  final int    rank;
  final int    points;
  final int    level;
  final int    streak;

  const LbEntry({
    required this.id,       required this.fullName,
    required this.username, required this.rank,
    required this.points,   required this.level,
    required this.streak,
  });

  String get levelEmoji {
    if (level >= 15) return '💎';
    if (level >= 10) return '🔥';
    if (level >= 7)  return '⭐';
    if (level >= 4)  return '🚀';
    if (level >= 2)  return '📚';
    return '🌱';
  }

  String get rankBadge => {1: '🥇', 2: '🥈', 3: '🥉'}[rank] ?? '#$rank';

  factory LbEntry.fromJson(Map<String, dynamic> j) => LbEntry(
    id:       j['_id']?.toString() ?? j['user_id']?.toString() ?? '',
    fullName: j['name'] ?? j['full_name'] ?? j['username'] ?? '',
    username: j['username'] ?? j['name'] ?? '',
    rank:     (j['rank']   ?? 0)  as int,
    points:   (j['xp'] ?? j['points'] ?? 0) as int,
    level:    (j['level']  ?? 1)  as int,
    streak:   (j['streak'] ?? 0)  as int,
  );
}

// ═══════════════════════════════════════════════════════
//  ACHIEVEMENT
// ═══════════════════════════════════════════════════════
class Achievement {
  final String id, name, description, emoji, rarity;
  final int    bonusPoints;
  final bool   isUnlocked;

  const Achievement({
    required this.id,          required this.name,
    required this.description, required this.emoji,
    required this.rarity,      required this.bonusPoints,
    required this.isUnlocked,
  });

  Color get rarityColor => const {
    'legendary': Color(0xFFFFD700),
    'epic':      Color(0xFF9C27B0),
    'rare':      Color(0xFF2196F3),
    'common':    Color(0xFF9D9BBE),
  }[rarity] ?? const Color(0xFF9D9BBE);

  String get rarityLabel => const {
    'legendary': 'LEGENDARY', 'epic': 'EPIC',
    'rare':      'RARE',      'common': 'COMMON',
  }[rarity] ?? 'COMMON';

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
    id:          j['id']          ?? '',
    name:        j['name']        ?? '',
    description: j['description'] ?? '',
    emoji:       j['emoji']       ?? '🏆',
    rarity:      j['rarity']      ?? 'common',
    bonusPoints: (j['bonus_points'] ?? 0) as int,
    isUnlocked:  j['is_unlocked'] ?? false,
  );
}

// ═══════════════════════════════════════════════════════
//  CHAT MESSAGE
// ═══════════════════════════════════════════════════════
class ChatMsg {
  final String   id;
  final String   role;
  final String   content;
  final DateTime timestamp;
  final List<TaskSuggestion>? tasks;
  final bool     isError;

  const ChatMsg({
    required this.id,        required this.role,
    required this.content,   required this.timestamp,
    this.tasks, this.isError = false,
  });

  bool get isUser      => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasTasks    => tasks != null && tasks!.isNotEmpty;

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
    id:        j['id']      ?? '',
    role:      j['role']    ?? 'user',
    content:   j['content'] ?? '',
    timestamp: j['ts'] != null
        ? DateTime.tryParse(j['ts'].toString()) ?? DateTime.now()
        : DateTime.now(),
    tasks: (j['tasks'] as List?)
        ?.map((t) => TaskSuggestion.fromJson(t as Map<String, dynamic>))
        .toList(),
    isError: j['err'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id':      id,
    'role':    role,
    'content': content,
    'ts':      timestamp.toIso8601String(),
    'tasks':   tasks?.map((t) => t.toJson()).toList(),
    'err':     isError,
  };
}

// ═══════════════════════════════════════════════════════
//  TASK SUGGESTION (from AI Chat)
// ═══════════════════════════════════════════════════════
class TaskSuggestion {
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int    durationMinutes;
  final int    estimatedPoints;
  bool         isSelected;

  TaskSuggestion({
    required this.title,           required this.description,
    required this.category,        required this.difficulty,
    required this.durationMinutes, required this.estimatedPoints,
    this.isSelected = true,
  });

  factory TaskSuggestion.fromJson(Map<String, dynamic> j) => TaskSuggestion(
    title:           j['title']           ?? '',
    description:     j['description']     ?? '',
    category:        j['category']        ?? 'study',
    difficulty:      j['difficulty']      ?? 'medium',
    durationMinutes: (j['duration_minutes'] ?? 30) as int,
    estimatedPoints: (j['estimated_points'] ?? 50) as int,
  );

  Map<String, dynamic> toJson() => {
    'title':            title,
    'description':      description,
    'category':         category,
    'difficulty':       difficulty,
    'duration_minutes': durationMinutes,
    'estimated_points': estimatedPoints,
  };
}
