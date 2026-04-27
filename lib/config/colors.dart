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

  // ─── GRADIENTS ──────────────────────────────────────────
  // We collapsed everything to two-stop gradients on the same hue so the
  // app stops looking like a Lisa Frank tribute. Most surfaces are flat
  // now; gradients only show up on the primary CTA + the XP ring.
  static List<Color> get gradPrimary => ThemePresets.current.gradPrimary;
  static List<Color> get gradCosmic => ThemePresets.current.gradCosmic;
  static List<Color> get gradAurora => ThemePresets.current.gradAurora;
  static List<Color> get gradStellar => [accent, accent];
  static List<Color> get gradGold    => [accent, accent];
  static List<Color> get gradSuccess => [success, success];
  static List<Color> get gradWarning => [accent, danger];
  static List<Color> get gradAccent  => [accent, accent];
  static List<Color> get gradCyan    => [info, info];
  static List<Color> get gradFire    => [accent, danger];

  // ─── CATEGORY COLORS — restrained palette (single accent per kind) ─
  static const cat = <String, Color>{
    'study':        Color(0xFF7C3AED),
    'exercise':     Color(0xFF10B981),
    'reading':      Color(0xFFEC4899),
    'meditation':   Color(0xFF3B82F6),
    'social':       Color(0xFFF59E0B),
    'creative':     Color(0xFFEF4444),
    'productivity': Color(0xFF3B82F6),
    'challenge':    Color(0xFF7C3AED),
  };

  // ─── GLOW (used very rarely now) ──────────────────────
  static Color get glowPrimary => primary.withOpacity(0.20);
  static Color get glowGold    => accent.withOpacity(0.20);
  static Color get glowCyan    => secondary.withOpacity(0.20);

  // ─── TITLE TEXT — solid, no rainbow ───────────────────
  // Kept for back-compat: callers using ShaderMask + titleGradient now
  // get a flat near-foreground color in both stops, which renders
  // visually identical to plain Text(color: AppColors.txt).
  static List<Color> get titleGradient => [txt, txt];
}
