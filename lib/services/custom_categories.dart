import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

class CustomCategory {
  final String id;
  String name;
  String emoji;
  Color color;

  CustomCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color.value,
      };

  factory CustomCategory.fromJson(Map<String, dynamic> j) =>
      CustomCategory(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '',
        color: Color(j['color'] as int? ?? 0xFFA855F7),
      );
}

class CustomCategoriesStorage {
  static const _keyBase = 'motivai_custom_categories_v1';
  static String get _key => UserScope.key(_keyBase);

  static Future<List<CustomCategory>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              CustomCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<CustomCategory> cats) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(cats.map((c) => c.toJson()).toList()));
  }

  static Future<CustomCategory> add({
    required String name,
    required String emoji,
    required Color color,
  }) async {
    final cats = await load();
    final c = CustomCategory(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      color: color,
    );
    cats.add(c);
    await save(cats);
    return c;
  }

  static Future<void> remove(String id) async {
    final cats = await load();
    cats.removeWhere((c) => c.id == id);
    await save(cats);
  }
}
