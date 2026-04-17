import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette — switches between dark/light via [isDark].
class C {
  static bool _dark = true;
  static void setDark(bool v) => _dark = v;
  static bool get isDark => _dark;

  // ── Brand colors (constant) ───────────────────────────
  static const primary      = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9B94FF);
  static const accent       = Color(0xFFFF6584);
  static const gold         = Color(0xFFFFD700);
  static const success      = Color(0xFF43E97B);
  static const teal         = Color(0xFF38F9D7);
  static const warning      = Color(0xFFFFA726);
  static const error        = Color(0xFFEF5350);

  // ── Theme-aware colors ────────────────────────────────
  static Color get bg      => _dark ? const Color(0xFF0F0E17) : const Color(0xFFF5F5FA);
  static Color get surface => _dark ? const Color(0xFF1A1929) : const Color(0xFFFFFFFF);
  static Color get card    => _dark ? const Color(0xFF242338) : const Color(0xFFFFFFFF);
  static Color get border  => _dark ? const Color(0xFF2E2D45) : const Color(0xFFE0E0E8);
  static Color get txt     => _dark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A2E);
  static Color get sub     => _dark ? const Color(0xFF9D9BBE) : const Color(0xFF6E6E8A);

  // ── Gradients ─────────────────────────────────────────
  static const List<Color> gradPrimary = [Color(0xFF6C63FF), Color(0xFF9B94FF)];
  static const List<Color> gradAccent  = [Color(0xFFFF6584), Color(0xFFFF8E53)];
  static const List<Color> gradGreen   = [Color(0xFF43E97B), Color(0xFF38F9D7)];
  static const List<Color> gradGold    = [Color(0xFFFFD700), Color(0xFFFFA726)];

  // ── Category colors ───────────────────────────────────
  static const Map<String, Color> cat = {
    'study':        Color(0xFF6C63FF),
    'exercise':     Color(0xFF43E97B),
    'reading':      Color(0xFFFF6584),
    'meditation':   Color(0xFF38F9D7),
    'social':       Color(0xFFFFD700),
    'creative':     Color(0xFFFF8E53),
    'productivity': Color(0xFF9B94FF),
    'challenge':    Color(0xFFEF5350),
  };
}

/// Provides full [ThemeData] for dark & light modes.
/// Both themes use Google Fonts Sora and are AnimatedTheme-friendly
/// because they return complete ThemeData instances with matching
/// brightness, so Flutter interpolates between them smoothly.
class AppTheme {
  static ThemeData get dark  => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark  = brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF5F5FA);
    final surface = isDark ? const Color(0xFF1A1929) : const Color(0xFFFFFFFF);
    final card    = isDark ? const Color(0xFF242338) : const Color(0xFFFFFFFF);
    final border  = isDark ? const Color(0xFF2E2D45) : const Color(0xFFE0E0E8);
    final txt     = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A2E);
    final sub     = isDark ? const Color(0xFF9D9BBE) : const Color(0xFF6E6E8A);

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.soraTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: C.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: C.primary,
        onPrimary: Colors.white,
        secondary: C.accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: txt,
        error: C.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: txt,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txt,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.primary, width: 2),
        ),
        labelStyle: TextStyle(color: sub),
        hintStyle: TextStyle(color: sub),
        prefixIconColor: sub,
        suffixIconColor: sub,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: C.primary,
        unselectedItemColor: sub,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogBackgroundColor: card,
      dividerColor: border,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
