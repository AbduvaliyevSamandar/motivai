import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Each preset carries both dark and light surface colors plus accents.
class ThemePreset {
  final String id;
  final String name;
  final String emoji;

  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color pink;
  final Color info;
  final Color success;
  final Color danger;

  // Surfaces (dark mode)
  final Color bgDark;
  final Color bgDeepDark;
  final Color surfaceDark;
  final Color cardDark;
  final Color glassDark;
  final Color borderDark;
  final Color dividerDark;
  final Color txtDark;
  final Color subDark;
  final Color hintDark;

  // Surfaces (light mode)
  final Color bgLight;
  final Color bgDeepLight;
  final Color surfaceLight;
  final Color cardLight;
  final Color glassLight;
  final Color borderLight;
  final Color dividerLight;
  final Color txtLight;
  final Color subLight;
  final Color hintLight;

  // Gradients (used sparingly — mostly for the brand call-to-action button
  // and the XP ring). All collapsed to two-stop gradients for restraint.
  final List<Color> gradPrimary;
  final List<Color> gradCosmic;
  final List<Color> gradAurora;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.pink,
    required this.info,
    required this.success,
    required this.danger,
    required this.bgDark,
    required this.bgDeepDark,
    required this.surfaceDark,
    required this.cardDark,
    required this.glassDark,
    required this.borderDark,
    required this.dividerDark,
    required this.txtDark,
    required this.subDark,
    required this.hintDark,
    required this.bgLight,
    required this.bgDeepLight,
    required this.surfaceLight,
    required this.cardLight,
    required this.glassLight,
    required this.borderLight,
    required this.dividerLight,
    required this.txtLight,
    required this.subLight,
    required this.hintLight,
    required this.gradPrimary,
    required this.gradCosmic,
    required this.gradAurora,
  });
}

class ThemePresets {
  static const _key = 'motivai_theme_preset';
  static ThemePreset _current = indigo;

  static ThemePreset get current => _current;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_key);
    if (id != null) {
      _current = byId(id) ?? indigo;
    }
  }

  static Future<void> set(String id) async {
    final preset = byId(id);
    if (preset == null) return;
    _current = preset;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, id);
  }

  static ThemePreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    // Backward compat: previous wild presets fall back to indigo so
    // existing users don't break.
    return indigo;
  }

  static List<ThemePreset> get all => const [
        indigo,
        forest,
        mono,
      ];

  // Shared neutral surfaces — most presets only differ by accent.
  static const _darkBg       = Color(0xFF0F0F14);
  static const _darkBgDeep   = Color(0xFF0A0A0F);
  static const _darkSurface  = Color(0xFF16161D);
  static const _darkCard     = Color(0xFF1A1A22);
  static const _darkBorder   = Color(0xFF26262F);
  static const _darkDivider  = Color(0xFF1F1F27);
  static const _darkTxt      = Color(0xFFEDEDF2);
  static const _darkSub      = Color(0xFF8B8B9A);
  static const _darkHint     = Color(0xFF555562);

  static const _lightBg       = Color(0xFFFAFAFB);
  static const _lightBgDeep   = Color(0xFFF3F3F6);
  static const _lightSurface  = Color(0xFFFFFFFF);
  static const _lightCard     = Color(0xFFFFFFFF);
  static const _lightBorder   = Color(0xFFE5E5EB);
  static const _lightDivider  = Color(0xFFEFEFF2);
  static const _lightTxt      = Color(0xFF111118);
  static const _lightSub      = Color(0xFF6E6E78);
  static const _lightHint     = Color(0xFFA1A1AA);

  // ─── INDIGO (default) ────────────────────────────────
  static const indigo = ThemePreset(
    id: 'indigo',
    name: 'Indigo',
    emoji: '\u{1F537}',
    primary: Color(0xFF7C3AED),       // single brand purple
    primaryDark: Color(0xFF6D28D9),
    secondary: Color(0xFF7C3AED),
    accent: Color(0xFFF59E0B),         // gold for streak/rewards only
    pink: Color(0xFFEC4899),
    info: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    bgDark: _darkBg,
    bgDeepDark: _darkBgDeep,
    surfaceDark: _darkSurface,
    cardDark: _darkCard,
    glassDark: _darkSurface,           // no glass — same as surface
    borderDark: _darkBorder,
    dividerDark: _darkDivider,
    txtDark: _darkTxt,
    subDark: _darkSub,
    hintDark: _darkHint,
    bgLight: _lightBg,
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightSurface,
    borderLight: _lightBorder,
    dividerLight: _lightDivider,
    txtLight: _lightTxt,
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    gradCosmic:  [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    gradAurora:  [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  );

  // ─── FOREST (green) ──────────────────────────────────
  static const forest = ThemePreset(
    id: 'forest',
    name: 'Forest',
    emoji: '\u{1F332}',
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF14532D),
    secondary: Color(0xFF15803D),
    accent: Color(0xFFF59E0B),
    pink: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    bgDark: _darkBg,
    bgDeepDark: _darkBgDeep,
    surfaceDark: _darkSurface,
    cardDark: _darkCard,
    glassDark: _darkSurface,
    borderDark: _darkBorder,
    dividerDark: _darkDivider,
    txtDark: _darkTxt,
    subDark: _darkSub,
    hintDark: _darkHint,
    bgLight: _lightBg,
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightSurface,
    borderLight: _lightBorder,
    dividerLight: _lightDivider,
    txtLight: _lightTxt,
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFF15803D), Color(0xFF14532D)],
    gradCosmic:  [Color(0xFF15803D), Color(0xFF14532D)],
    gradAurora:  [Color(0xFF15803D), Color(0xFF14532D)],
  );

  // ─── MONO (grayscale + gold) ─────────────────────────
  static const mono = ThemePreset(
    id: 'mono',
    name: 'Mono',
    emoji: '\u{26AB}',
    primary: Color(0xFF18181B),
    primaryDark: Color(0xFF09090B),
    secondary: Color(0xFF52525B),
    accent: Color(0xFFF59E0B),
    pink: Color(0xFF52525B),
    info: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    bgDark: Color(0xFF09090B),
    bgDeepDark: Color(0xFF000000),
    surfaceDark: Color(0xFF18181B),
    cardDark: Color(0xFF27272A),
    glassDark: Color(0xFF18181B),
    borderDark: Color(0xFF3F3F46),
    dividerDark: Color(0xFF27272A),
    txtDark: Color(0xFFFAFAFA),
    subDark: Color(0xFFA1A1AA),
    hintDark: Color(0xFF52525B),
    bgLight: Color(0xFFFAFAFA),
    bgDeepLight: Color(0xFFF4F4F5),
    surfaceLight: Color(0xFFFFFFFF),
    cardLight: Color(0xFFFFFFFF),
    glassLight: Color(0xFFFFFFFF),
    borderLight: Color(0xFFE4E4E7),
    dividerLight: Color(0xFFF4F4F5),
    txtLight: Color(0xFF18181B),
    subLight: Color(0xFF52525B),
    hintLight: Color(0xFFA1A1AA),
    gradPrimary: [Color(0xFF27272A), Color(0xFF09090B)],
    gradCosmic:  [Color(0xFF27272A), Color(0xFF09090B)],
    gradAurora:  [Color(0xFF27272A), Color(0xFF09090B)],
  );
}
