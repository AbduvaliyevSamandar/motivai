import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// Simple 7-day paired challenge. Since we don't have real-time sync,
/// both sides track independently and compare by reported scores.
class FriendChallenge {
  final String id;
  final String friendId;
  final String friendName;
  final String title;
  final int days;
  final int goalTasksPerDay;
  final DateTime startAt;
  final Map<String, int> myDaily; // date -> tasks that day
  final Map<String, int> friendDaily;

  FriendChallenge({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.title,
    required this.days,
    required this.goalTasksPerDay,
    required this.startAt,
    required this.myDaily,
    required this.friendDaily,
  });

  int get myTotal => myDaily.values.fold(0, (a, b) => a + b);
  int get friendTotal => friendDaily.values.fold(0, (a, b) => a + b);

  int get goalTotal => goalTasksPerDay * days;

  bool get isActive {
    final end = startAt.add(Duration(days: days));
    return DateTime.now().isBefore(end);
  }

  int get daysLeft {
    final end = startAt.add(Duration(days: days));
    return end.difference(DateTime.now()).inDays.clamp(0, days);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'friendId': friendId,
        'friendName': friendName,
        'title': title,
        'days': days,
        'goalTasksPerDay': goalTasksPerDay,
        'startAt': startAt.toIso8601String(),
        'myDaily': myDaily,
        'friendDaily': friendDaily,
      };

  static FriendChallenge fromJson(Map<String, dynamic> j) =>
      FriendChallenge(
        id: j['id'] ?? '',
        friendId: j['friendId'] ?? '',
        friendName: j['friendName'] ?? '',
        title: j['title'] ?? '',
        days: (j['days'] as num?)?.toInt() ?? 7,
        goalTasksPerDay:
            (j['goalTasksPerDay'] as num?)?.toInt() ?? 3,
        startAt: DateTime.tryParse(j['startAt'] ?? '') ??
            DateTime.now(),
        myDaily: ((j['myDaily'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        friendDaily: ((j['friendDaily'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      );
}

class FriendChallenges {
  static const _keyBase = 'motivai_friend_challenges_v1';
  static String get _key => UserScope.key(_keyBase);
  static List<FriendChallenge> _cache = [];
  static bool _loaded = false;
  static String _loadedFor = '';

  static Future<void> _ensure() async {
    if (_loaded && _loadedFor == UserScope.userId) return;
        _cache = [];
        _loadedFor = UserScope.userId;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) =>
                FriendChallenge.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  static Future<List<FriendChallenge>> all() async {
    await _ensure();
    return List<FriendChallenge>.from(_cache);
  }

  static Future<FriendChallenge> create({
    required String friendId,
    required String friendName,
    required String title,
    required int days,
    required int goalTasksPerDay,
  }) async {
    await _ensure();
    final c = FriendChallenge(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      friendId: friendId,
      friendName: friendName,
      title: title,
      days: days,
      goalTasksPerDay: goalTasksPerDay,
      startAt: DateTime.now(),
      myDaily: {},
      friendDaily: {},
    );
    _cache.add(c);
    await _persist();
    return c;
  }

  static Future<void> remove(String id) async {
    await _ensure();
    _cache.removeWhere((c) => c.id == id);
    await _persist();
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<void> recordMyTask() async {
    await _ensure();
    final key = _todayKey();
    bool dirty = false;
    for (final c in _cache) {
      if (!c.isActive) continue;
      c.myDaily[key] = (c.myDaily[key] ?? 0) + 1;
      dirty = true;
    }
    if (dirty) await _persist();
  }

  static Future<void> recordFriendTask(
      String challengeId, int count) async {
    await _ensure();
    final key = _todayKey();
    final c = _cache.firstWhere((c) => c.id == challengeId,
        orElse: () => throw StateError('challenge not found'));
    c.friendDaily[key] = (c.friendDaily[key] ?? 0) + count;
    await _persist();
  }
}
