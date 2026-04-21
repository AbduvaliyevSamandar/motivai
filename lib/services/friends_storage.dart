import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

/// Local friends list (no backend yet) — each friend is remembered by name,
/// invite-code, emoji and the XP/streak they reported last. Good enough to
/// see who's in your study group, but the numbers don't auto-sync.
class Friend {
  final String id;
  final String name;
  final String code;
  final String emoji;
  int coinsSent;
  int xp;
  int streak;
  String? lastPing;
  int coinsReceived;

  Friend({
    required this.id,
    required this.name,
    required this.code,
    required this.emoji,
    this.coinsSent = 0,
    this.xp = 0,
    this.streak = 0,
    this.lastPing,
    this.coinsReceived = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'emoji': emoji,
        'coinsSent': coinsSent,
        'xp': xp,
        'streak': streak,
        'lastPing': lastPing,
        'coinsReceived': coinsReceived,
      };

  static Friend fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        code: j['code'] ?? '',
        emoji: j['emoji'] ?? '\u{1F642}',
        coinsSent: (j['coinsSent'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        lastPing: j['lastPing'],
        coinsReceived: (j['coinsReceived'] as num?)?.toInt() ?? 0,
      );
}

class FriendsStorage {
  static const _listKey = 'motivai_friends_v1';
  static const _myCodeKey = 'motivai_my_invite_code';

  static List<Friend> _cache = [];
  static String? _myCode;
  static bool _loaded = false;

  static Future<void> _ensure() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_listKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
    _myCode = p.getString(_myCodeKey);
    if (_myCode == null) {
      _myCode = _generateCode();
      await p.setString(_myCodeKey, _myCode!);
    }
    _loaded = true;
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  static Future<String> myCode() async {
    await _ensure();
    return _myCode!;
  }

  static Future<List<Friend>> all() async {
    await _ensure();
    return List<Friend>.from(_cache);
  }

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_listKey,
        jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  static Future<bool> add({
    required String name,
    required String code,
    String emoji = '\u{1F642}',
  }) async {
    await _ensure();
    if (name.trim().isEmpty || code.trim().isEmpty) return false;
    final upper = code.toUpperCase().trim();
    if (upper == _myCode) return false; // can't add self
    if (_cache.any((f) => f.code == upper)) return false;
    _cache.add(Friend(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      code: upper,
      emoji: emoji,
    ));
    await _persist();
    return true;
  }

  static Future<void> remove(String id) async {
    await _ensure();
    _cache.removeWhere((f) => f.id == id);
    await _persist();
  }

  static Future<void> sendCoins(String id, int amount) async {
    await _ensure();
    final f = _cache.firstWhere((f) => f.id == id);
    f.coinsSent += amount;
    await _persist();
  }

  static Future<void> ping(String id, String message) async {
    await _ensure();
    final f = _cache.firstWhere((f) => f.id == id);
    f.lastPing = message;
    await _persist();
  }
}
