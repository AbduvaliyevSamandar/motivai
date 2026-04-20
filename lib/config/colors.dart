import 'package:flutter/material.dart';

/// MotivAI — Nebula Premium design system
class AppColors {
  static bool _dark = true;
  static void setDark(bool v) => _dark = v;
  static bool get isDark => _dark;

  // ─── BRAND ACCENTS (cosmic palette) ────────────────────────
  static const primary = Color(0xFFA855F7); // cosmic violet
  static const primaryDark = Color(0xFF7C3AED);
  static const secondary = Color(0xFF00D9FF); // electric cyan
  static const accent = Color(0xFFFCD34D); // stellar gold
  static const success = Color(0xFF34D399); // aurora green
  static const danger = Color(0xFFF87171); // nova red
  static const info = Color(0xFF60A5FA); // nebula blue
  static const pink = Color(0xFFF472B6); // cosmic pink

  // ─── NEBULA SURFACES ───────────────────────────────────────
  static Color get bg => _dark
      ? const Color(0xFF08091A) // deep space
      : const Color(0xFFF7F6FB);

  static Color get bgDeep => _dark
      ? const Color(0xFF05061A)
      : const Color(0xFFEFEDF7);

  static Color get surface => _dark
      ? const Color(0xFF111327)
      : const Color(0xFFFFFFFF);

  static Color get card => _dark
      ? const Color(0xFF161933)
      : const Color(0xFFFFFFFF);

  // Glass surface for frosted cards
  static Color get glass => _dark
      ? const Color(0x3316193D)
      : const Color(0xCCFFFFFF);

  static Color get glassBorder => _dark
      ? const Color(0x4DA855F7)
      : const Color(0x33A855F7);

  static Color get border => _dark
      ? const Color(0xFF252847)
      : const Color(0xFFE5E3F0);

  static Color get divider => _dark
      ? const Color(0xFF1A1D36)
      : const Color(0xFFF0EEF7);

  // ─── TYPOGRAPHY ────────────────────────────────────────────
  static Color get txt => _dark
      ? const Color(0xFFF1F1FA)
      : const Color(0xFF0F1028);

  static Color get sub => _dark
      ? const Color(0xFFA5A8C7)
      : const Color(0xFF6B6E8F);

  static Color get hint => _dark
      ? const Color(0xFF6C6F8E)
      : const Color(0xFFA5A8C7);

  // ─── GRADIENTS (aurora & cosmic) ───────────────────────────
  // Primary — cosmic aurora (violet → cyan)
  static const gradPrimary = [Color(0xFFA855F7), Color(0xFF7C3AED)];
  static const gradCosmic = [
    Color(0xFF7C3AED),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];
  static const gradAurora = [
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];
  static const gradStellar = [Color(0xFFFCD34D), Color(0xFFF59E0B)];
  static const gradGold = [Color(0xFFFCD34D), Color(0xFFF59E0B)];
  static const gradSuccess = [Color(0xFF34D399), Color(0xFF10B981)];
  static const gradWarning = [Color(0xFFF59E0B), Color(0xFFF87171)];
  static const gradAccent = [Color(0xFFF472B6), Color(0xFFA855F7)];
  static const gradCyan = [Color(0xFF00D9FF), Color(0xFF0891B2)];
  static const gradFire = [Color(0xFFFCD34D), Color(0xFFF87171)];

  // ─── CATEGORY COLORS ──────────────────────────────────────
  static const cat = <String, Color>{
    'study': Color(0xFFA855F7),
    'exercise': Color(0xFF34D399),
    'reading': Color(0xFFF472B6),
    'meditation': Color(0xFF00D9FF),
    'social': Color(0xFFFCD34D),
    'creative': Color(0xFFF87171),
    'productivity': Color(0xFF60A5FA),
    'challenge': Color(0xFFEC4899),
  };

  // ─── GLOW COLORS (for boxShadow) ──────────────────────────
  static Color get glowPrimary => primary.withOpacity(0.35);
  static Color get glowGold => accent.withOpacity(0.35);
  static Color get glowCyan => secondary.withOpacity(0.35);

  // ─── ADAPTIVE GRADIENTS (theme-aware titles etc) ─────────
  static List<Color> get titleGradient => _dark
      ? const [Color(0xFFFFFFFF), Color(0xFFE0D4FB)]
      : const [Color(0xFF4F46E5), Color(0xFFA855F7)];

  static List<Color> get softTitleGradient => _dark
      ? const [Color(0xFFFFFFFF), Color(0xFFBFB5EE)]
      : const [Color(0xFF1E1B4B), Color(0xFF4F46E5)];
}
