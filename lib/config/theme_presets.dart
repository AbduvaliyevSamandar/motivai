import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pre-defined theme palettes. User can switch between them in Settings.
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
  final Color bgDark;
  final Color surfaceDark;
  final Color cardDark;
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
    required this.surfaceDark,
    required this.cardDark,
    required this.gradPrimary,
    required this.gradCosmic,
    required this.gradAurora,
  });
}

class ThemePresets {
  static const _key = 'motivai_theme_preset';

  /// Active preset selected by user.
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

  // ─── Default: Nebula ─────────────────────────────
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
    surfaceDark: Color(0xFF111327),
    cardDark: Color(0xFF161933),
    gradPrimary: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    gradCosmic: [
      Color(0xFF7C3AED),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
    ],
    gradAurora: [
      Color(0xFF06B6D4),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
    ],
  );

  // ─── Ocean (blue-teal) ────────────────────────────
  static const ocean = ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    emoji: '\u{1F30A}',
    primary: Color(0xFF06B6D4),
    primaryDark: Color(0xFF0891B2),
    secondary: Color(0xFF60A5FA),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFF5EEAD4),
    info: Color(0xFF38BDF8),
    success: Color(0xFF10B981),
    danger: Color(0xFFF87171),
    bgDark: Color(0xFF051829),
    surfaceDark: Color(0xFF0C2136),
    cardDark: Color(0xFF112A47),
    gradPrimary: [Color(0xFF06B6D4), Color(0xFF0369A1)],
    gradCosmic: [
      Color(0xFF0EA5E9),
      Color(0xFF06B6D4),
      Color(0xFF14B8A6),
    ],
    gradAurora: [
      Color(0xFF38BDF8),
      Color(0xFF2DD4BF),
      Color(0xFF60A5FA),
    ],
  );

  // ─── Forest (green-earth) ─────────────────────────
  static const forest = ThemePreset(
    id: 'forest',
    name: 'Forest',
    emoji: '\u{1F332}',
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF16A34A),
    secondary: Color(0xFF84CC16),
    accent: Color(0xFFFBBF24),
    pink: Color(0xFFFCA5A5),
    info: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    danger: Color(0xFFEF4444),
    bgDark: Color(0xFF0A1A0A),
    surfaceDark: Color(0xFF0F2A14),
    cardDark: Color(0xFF14341B),
    gradPrimary: [Color(0xFF22C55E), Color(0xFF15803D)],
    gradCosmic: [
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF059669),
    ],
    gradAurora: [
      Color(0xFFA3E635),
      Color(0xFF22C55E),
      Color(0xFF14B8A6),
    ],
  );

  // ─── Cyberpunk (red-neon) ─────────────────────────
  static const cyberpunk = ThemePreset(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    emoji: '\u{1F47E}',
    primary: Color(0xFFF43F5E),
    primaryDark: Color(0xFFE11D48),
    secondary: Color(0xFF00F5FF),
    accent: Color(0xFFFACC15),
    pink: Color(0xFFFF1493),
    info: Color(0xFF22D3EE),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFDC2626),
    bgDark: Color(0xFF0A0014),
    surfaceDark: Color(0xFF16001F),
    cardDark: Color(0xFF1F0030),
    gradPrimary: [Color(0xFFF43F5E), Color(0xFFBE123C)],
    gradCosmic: [
      Color(0xFFF43F5E),
      Color(0xFFFF006E),
      Color(0xFF00F5FF),
    ],
    gradAurora: [
      Color(0xFFFF1493),
      Color(0xFFF43F5E),
      Color(0xFF00F5FF),
    ],
  );

  // ─── Soft Pastel (pink-lavender) ──────────────────
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
    surfaceDark: Color(0xFF241835),
    cardDark: Color(0xFF2D1F41),
    gradPrimary: [Color(0xFFE879F9), Color(0xFFC084FC)],
    gradCosmic: [
      Color(0xFFE879F9),
      Color(0xFFF9A8D4),
      Color(0xFFFBBF24),
    ],
    gradAurora: [
      Color(0xFFBFDBFE),
      Color(0xFFF9A8D4),
      Color(0xFFFDE68A),
    ],
  );

  // ─── Minimal Mono (grey+single accent) ────────────
  static const mono = ThemePreset(
    id: 'mono',
    name: 'Mono',
    emoji: '\u{26AB}',
    primary: Color(0xFFF3F4F6),
    primaryDark: Color(0xFFD1D5DB),
    secondary: Color(0xFF9CA3AF),
    accent: Color(0xFFFCD34D),
    pink: Color(0xFFF472B6),
    info: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    bgDark: Color(0xFF000000),
    surfaceDark: Color(0xFF0A0A0A),
    cardDark: Color(0xFF141414),
    gradPrimary: [Color(0xFFF3F4F6), Color(0xFF9CA3AF)],
    gradCosmic: [
      Color(0xFFD1D5DB),
      Color(0xFFF3F4F6),
      Color(0xFFFCD34D),
    ],
    gradAurora: [
      Color(0xFF94A3B8),
      Color(0xFFD1D5DB),
      Color(0xFFFCD34D),
    ],
  );
}
