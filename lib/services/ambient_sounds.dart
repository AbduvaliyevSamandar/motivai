import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  const AmbientSound({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

class AmbientSounds {
  static const _key = 'motivai_ambient_sound';

  static const none = AmbientSound(
    id: 'none',
    name: 'Sukunat',
    emoji: '\u{1F507}',
    color: Color(0xFF94A3B8),
  );

  static const all = [
    none,
    AmbientSound(
        id: 'rain',
        name: 'Yomg\'ir',
        emoji: '\u{1F327}\uFE0F',
        color: Color(0xFF60A5FA)),
    AmbientSound(
        id: 'forest',
        name: 'O\'rmon',
        emoji: '\u{1F332}',
        color: Color(0xFF22C55E)),
    AmbientSound(
        id: 'cafe',
        name: 'Kafe',
        emoji: '\u{2615}',
        color: Color(0xFFA0522D)),
    AmbientSound(
        id: 'white_noise',
        name: 'Oq shovqin',
        emoji: '\u{1F4FB}',
        color: Color(0xFFE5E3F0)),
    AmbientSound(
        id: 'lofi',
        name: 'Lo-fi',
        emoji: '\u{1F3A7}',
        color: Color(0xFFF472B6)),
    AmbientSound(
        id: 'ocean',
        name: 'Dengiz',
        emoji: '\u{1F30A}',
        color: Color(0xFF06B6D4)),
    AmbientSound(
        id: 'fire',
        name: 'Olov',
        emoji: '\u{1F525}',
        color: Color(0xFFF87171)),
  ];

  static Future<String> selectedId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key) ?? 'none';
  }

  static Future<AmbientSound> selected() async {
    final id = await selectedId();
    return all.firstWhere((s) => s.id == id, orElse: () => none);
  }

  static Future<void> select(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, id);
  }
}
