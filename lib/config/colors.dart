import 'package:flutter/material.dart';
import 'theme_presets.dart';

/// MotivAI — theme-driven design system
class AppColors {
  static bool _dark = true;
  static void setDark(bool v) => _dark = v;
  static bool get isDark => _dark;

  // ─── BRAND ACCENTS (driven by active preset) ──────────────
  static Color get primary => ThemePresets.current.primary;
  static Color get primaryDark => ThemePresets.current.primaryDark;
  static Color get secondary => ThemePresets.current.secondary;
  static Color get accent => ThemePresets.current.accent;
  static Color get success => ThemePresets.current.success;
  static Color get danger => ThemePresets.current.danger;
  static Color get info => ThemePresets.current.info;
  static Color get pink => ThemePresets.current.pink;

  // ─── SURFACES (theme-aware + mode-aware) ──────────────────
  static Color get bg => _dark
      ? ThemePresets.current.bgDark
      : ThemePresets.current.bgLight;

  static Color get bgDeep => _dark
      ? ThemePresets.current.bgDeepDark
      : ThemePresets.current.bgDeepLight;

  static Color get surface => _dark
      ? ThemePresets.current.surfaceDark
      : ThemePresets.current.surfaceLight;

  static Color get card => _dark
      ? ThemePresets.current.cardDark
      : ThemePresets.current.cardLight;

  static Color get glass => _dark
      ? ThemePresets.current.glassDark
      : ThemePresets.current.glassLight;

  static Color get glassBorder => primary.withOpacity(_dark ? 0.3 : 0.2);

  static Color get border => _dark
      ? ThemePresets.current.borderDark
      : ThemePresets.current.borderLight;

  static Color get divider => _dark
      ? ThemePresets.current.dividerDark
      : ThemePresets.current.dividerLight;

  // ─── TYPOGRAPHY ────────────────────────────────────────────
  static Color get txt => _dark
      ? ThemePresets.current.txtDark
      : ThemePresets.current.txtLight;
  static Color get sub => _dark
      ? ThemePresets.current.subDark
      : ThemePresets.current.subLight;
  static Color get hint => _dark
      ? ThemePresets.current.hintDark
      : ThemePresets.current.hintLight;

  // ─── GRADIENTS (theme-aware) ──────────────────────────────
  static List<Color> get gradPrimary => ThemePresets.current.gradPrimary;
  static List<Color> get gradCosmic => ThemePresets.current.gradCosmic;
  static List<Color> get gradAurora => ThemePresets.current.gradAurora;
  static const gradStellar = [Color(0xFFFCD34D), Color(0xFFF59E0B)];
  static const gradGold = [Color(0xFFFCD34D), Color(0xFFF59E0B)];
  static const gradSuccess = [Color(0xFF34D399), Color(0xFF10B981)];
  static const gradWarning = [Color(0xFFF59E0B), Color(0xFFF87171)];
  static List<Color> get gradAccent => [pink, primary];
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

  // ─── GLOW ─────────────────────────────────────────────────
  static Color get glowPrimary => primary.withOpacity(0.35);
  static Color get glowGold => accent.withOpacity(0.35);
  static Color get glowCyan => secondary.withOpacity(0.35);

  // ─── ADAPTIVE TITLE GRADIENT ──────────────────────────────
  static List<Color> get titleGradient => _dark
      ? [Colors.white, primary.withOpacity(0.6)]
      : [primary, primaryDark];
}
