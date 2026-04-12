import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const primary     = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4A42CC);
  static const accent      = Color(0xFFFF6584);
  static const gold        = Color(0xFFFFD700);
  static const success     = Color(0xFF43E97B);
  static const teal        = Color(0xFF38F9D7);
  static const warning     = Color(0xFFFFA726);
  static const error       = Color(0xFFEF5350);

  static const bg      = Color(0xFF0F0E17);
  static const surface = Color(0xFF1A1929);
  static const card    = Color(0xFF242338);
  static const border  = Color(0xFF2E2D45);
  static const txt     = Color(0xFFF5F5F5);
  static const sub     = Color(0xFF9D9BBE);

  static const List<Color> gradPrimary = [Color(0xFF6C63FF), Color(0xFF9B94FF)];
  static const List<Color> gradAccent  = [Color(0xFFFF6584), Color(0xFFFF8E53)];
  static const List<Color> gradGreen   = [Color(0xFF43E97B), Color(0xFF38F9D7)];
  static const List<Color> gradGold    = [Color(0xFFFFD700), Color(0xFFFFA726)];

  static const catColors = <String, Color>{
    'study':       Color(0xFF6C63FF),
    'exercise':    Color(0xFF43E97B),
    'reading':     Color(0xFFFF6584),
    'meditation':  Color(0xFF38F9D7),
    'social':      Color(0xFFFFD700),
    'creative':    Color(0xFFFF8E53),
    'productivity':Color(0xFF9B94FF),
    'challenge':   Color(0xFFEF5350),
  };
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    primaryColor: C.primary,
    colorScheme: const ColorScheme.dark(
      primary: C.primary,
      secondary: C.accent,
      surface: C.surface,
      error: C.error,
    ),
    textTheme: GoogleFonts.soraTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      foregroundColor: C.txt, centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: C.card, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: C.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.primary, width: 2)),
      labelStyle: const TextStyle(color: C.sub),
      hintStyle: const TextStyle(color: C.sub),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: C.surface,
      selectedItemColor: C.primary,
      unselectedItemColor: C.sub,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
