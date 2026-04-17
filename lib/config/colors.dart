import 'package:flutter/material.dart';

class AppColors {
  static bool _dark = false;
  static void setDark(bool v) => _dark = v;
  static bool get isDark => _dark;

  // Brand (const)
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);

  // Theme-aware (getters)
  static Color get bg =>
      _dark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FD);
  static Color get surface =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get card =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get border =>
      _dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  static Color get divider =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6);
  static Color get txt =>
      _dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E1B4B);
  static Color get sub =>
      _dark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  static Color get hint =>
      _dark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

  // Gradients
  static const gradPrimary = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradWarning = [Color(0xFFF59E0B), Color(0xFFEF4444)];
  static const gradGold = [Color(0xFFFFD700), Color(0xFFFFA726)];
  static const gradAccent = [Color(0xFFFF6584), Color(0xFFFF8E53)];

  // Category
  static const cat = <String, Color>{
    'study': Color(0xFF6366F1),
    'exercise': Color(0xFF10B981),
    'reading': Color(0xFFFF6584),
    'meditation': Color(0xFF06B6D4),
    'social': Color(0xFFF59E0B),
    'creative': Color(0xFFFF8E53),
    'productivity': Color(0xFF8B5CF6),
    'challenge': Color(0xFFEF4444),
  };
}
