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

  // Gradients
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
  static ThemePreset _current = nebula;

  static ThemePreset get current => _current;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_key);
    if (id != null) {
      _current = byId(id) ?? nebula;
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
    return null;
  }

  static List<ThemePreset> get all => const [
        nebula,
        ocean,
        forest,
        cyberpunk,
        pastel,
        mono,
      ];

  // ─── Standard light values (shared by most) ───────────
  static const _lightBg = Color(0xFFF7F6FB);
  static const _lightBgDeep = Color(0xFFEFEDF7);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightCard = Color(0xFFFFFFFF);
  static const _lightGlass = Color(0xCCFFFFFF);
  static const _lightBorder = Color(0xFFE5E3F0);
  static const _lightDivider = Color(0xFFF0EEF7);
  static const _lightTxt = Color(0xFF0F1028);
  static const _lightSub = Color(0xFF6B6E8F);
  static const _lightHint = Color(0xFFA5A8C7);

  // ─── NEBULA (default, purple+cyan) ──────────────────
  static const nebula = ThemePreset(
    id: 'nebula',
    name: 'Nebula',
    emoji: '\u{1F30C}',
    primary: Color(0xFFA855F7),
    primaryDark: Color(0xFF7C3AED),
    secondary: Color(0xFF00D9FF),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFFF472B6),
    info: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    bgDark: Color(0xFF08091A),
    bgDeepDark: Color(0xFF05061A),
    surfaceDark: Color(0xFF111327),
    cardDark: Color(0xFF161933),
    glassDark: Color(0x3316193D),
    borderDark: Color(0xFF252847),
    dividerDark: Color(0xFF1A1D36),
    txtDark: Color(0xFFF1F1FA),
    subDark: Color(0xFFA5A8C7),
    hintDark: Color(0xFF6C6F8E),
    bgLight: _lightBg,
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: _lightBorder,
    dividerLight: _lightDivider,
    txtLight: _lightTxt,
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    gradCosmic: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFEC4899)],
    gradAurora: [Color(0xFF06B6D4), Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  // ─── OCEAN (blue-teal) ──────────────────────────────
  static const ocean = ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    emoji: '\u{1F30A}',
    primary: Color(0xFF06B6D4),
    primaryDark: Color(0xFF0891B2),
    secondary: Color(0xFF38BDF8),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFF5EEAD4),
    info: Color(0xFF60A5FA),
    success: Color(0xFF10B981),
    danger: Color(0xFFF87171),
    bgDark: Color(0xFF051829),
    bgDeepDark: Color(0xFF021320),
    surfaceDark: Color(0xFF0C2136),
    cardDark: Color(0xFF112A47),
    glassDark: Color(0x33112A47),
    borderDark: Color(0xFF1E3A5F),
    dividerDark: Color(0xFF0F2136),
    txtDark: Color(0xFFE0F2FE),
    subDark: Color(0xFF94BDD4),
    hintDark: Color(0xFF5F8AA3),
    bgLight: Color(0xFFF0FBFF),
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: Color(0xFFD6EAF8),
    dividerLight: _lightDivider,
    txtLight: Color(0xFF0A2540),
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFF06B6D4), Color(0xFF0369A1)],
    gradCosmic: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF14B8A6)],
    gradAurora: [Color(0xFF38BDF8), Color(0xFF2DD4BF), Color(0xFF60A5FA)],
  );

  // ─── FOREST (green-earth) ───────────────────────────
  static const forest = ThemePreset(
    id: 'forest',
    name: 'Forest',
    emoji: '\u{1F332}',
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF15803D),
    secondary: Color(0xFF84CC16),
    accent: Color(0xFFFBBF24),
    pink: Color(0xFFFCA5A5),
    info: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    danger: Color(0xFFEF4444),
    bgDark: Color(0xFF0A1A0A),
    bgDeepDark: Color(0xFF061006),
    surfaceDark: Color(0xFF0F2A14),
    cardDark: Color(0xFF14341B),
    glassDark: Color(0x3314341B),
    borderDark: Color(0xFF1F4A29),
    dividerDark: Color(0xFF102818),
    txtDark: Color(0xFFE8F5E9),
    subDark: Color(0xFF9CC9A3),
    hintDark: Color(0xFF5E8966),
    bgLight: Color(0xFFF2FCF4),
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: Color(0xFFD4EDDA),
    dividerLight: _lightDivider,
    txtLight: Color(0xFF14532D),
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFF22C55E), Color(0xFF15803D)],
    gradCosmic: [Color(0xFF84CC16), Color(0xFF22C55E), Color(0xFF059669)],
    gradAurora: [Color(0xFFA3E635), Color(0xFF22C55E), Color(0xFF14B8A6)],
  );

  // ─── CYBERPUNK (neon pink + cyan) ───────────────────
  static const cyberpunk = ThemePreset(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    emoji: '\u{1F47E}',
    primary: Color(0xFFF43F5E),
    primaryDark: Color(0xFFBE123C),
    secondary: Color(0xFF00F5FF),
    accent: Color(0xFFFACC15),
    pink: Color(0xFFFF1493),
    info: Color(0xFF22D3EE),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFDC2626),
    bgDark: Color(0xFF0A0014),
    bgDeepDark: Color(0xFF05000A),
    surfaceDark: Color(0xFF16001F),
    cardDark: Color(0xFF1F0030),
    glassDark: Color(0x331F0030),
    borderDark: Color(0xFF3B0B5C),
    dividerDark: Color(0xFF1A0029),
    txtDark: Color(0xFFFDF4FF),
    subDark: Color(0xFFB790C4),
    hintDark: Color(0xFF7D5A8F),
    bgLight: Color(0xFFFDF2F8),
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: Color(0xFFFCE4EC),
    dividerLight: _lightDivider,
    txtLight: Color(0xFF500724),
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFFF43F5E), Color(0xFFBE123C)],
    gradCosmic: [Color(0xFFF43F5E), Color(0xFFFF006E), Color(0xFF00F5FF)],
    gradAurora: [Color(0xFFFF1493), Color(0xFFF43F5E), Color(0xFF00F5FF)],
  );

  // ─── PASTEL (soft pink-lavender) ────────────────────
  static const pastel = ThemePreset(
    id: 'pastel',
    name: 'Pastel',
    emoji: '\u{1F338}',
    primary: Color(0xFFE879F9),
    primaryDark: Color(0xFFC026D3),
    secondary: Color(0xFF93C5FD),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFFF9A8D4),
    info: Color(0xFFA5B4FC),
    success: Color(0xFF86EFAC),
    danger: Color(0xFFFDA4AF),
    bgDark: Color(0xFF1A0F26),
    bgDeepDark: Color(0xFF120A1D),
    surfaceDark: Color(0xFF241835),
    cardDark: Color(0xFF2D1F41),
    glassDark: Color(0x332D1F41),
    borderDark: Color(0xFF3D2A55),
    dividerDark: Color(0xFF1F1530),
    txtDark: Color(0xFFFDF4FF),
    subDark: Color(0xFFB19BC9),
    hintDark: Color(0xFF7B6891),
    bgLight: Color(0xFFFCF3FF),
    bgDeepLight: _lightBgDeep,
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: Color(0xFFF3E8FF),
    dividerLight: _lightDivider,
    txtLight: Color(0xFF3B0764),
    subLight: _lightSub,
    hintLight: _lightHint,
    gradPrimary: [Color(0xFFE879F9), Color(0xFFC084FC)],
    gradCosmic: [Color(0xFFE879F9), Color(0xFFF9A8D4), Color(0xFFFBBF24)],
    gradAurora: [Color(0xFFBFDBFE), Color(0xFFF9A8D4), Color(0xFFFDE68A)],
  );

  // ─── MONO (grayscale + gold accent) ─────────────────
  static const mono = ThemePreset(
    id: 'mono',
    name: 'Mono',
    emoji: '\u{26AB}',
    primary: Color(0xFFE5E7EB),
    primaryDark: Color(0xFF9CA3AF),
    secondary: Color(0xFF9CA3AF),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFFF472B6),
    info: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    bgDark: Color(0xFF000000),
    bgDeepDark: Color(0xFF000000),
    surfaceDark: Color(0xFF0A0A0A),
    cardDark: Color(0xFF141414),
    glassDark: Color(0x33141414),
    borderDark: Color(0xFF2D2D2D),
    dividerDark: Color(0xFF1A1A1A),
    txtDark: Color(0xFFF9FAFB),
    subDark: Color(0xFFA1A1AA),
    hintDark: Color(0xFF6B7280),
    bgLight: Color(0xFFFAFAFA),
    bgDeepLight: Color(0xFFF0F0F0),
    surfaceLight: _lightSurface,
    cardLight: _lightCard,
    glassLight: _lightGlass,
    borderLight: Color(0xFFE5E5E5),
    dividerLight: Color(0xFFF0F0F0),
    txtLight: Color(0xFF18181B),
    subLight: Color(0xFF52525B),
    hintLight: Color(0xFFA1A1AA),
    gradPrimary: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
    gradCosmic: [Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFFCD34D)],
    gradAurora: [Color(0xFF94A3B8), Color(0xFFD1D5DB), Color(0xFFFCD34D)],
  );
}
