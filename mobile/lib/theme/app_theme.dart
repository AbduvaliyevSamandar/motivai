import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color secondary = Color(0xFF00D4AA);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color gold = Color(0xFFFFD700);
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceCard = Color(0xFF16213E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color divider = Color(0xFF2A2A4A);

  // XP Level colors
  static const List<Color> levelColors = [
    Color(0xFF78909C), // Grey - Level 1-4
    Color(0xFF66BB6A), // Green - Level 5-9
    Color(0xFF42A5F5), // Blue - Level 10-19
    Color(0xFFAB47BC), // Purple - Level 20-29
    Color(0xFFFFD700), // Gold - Level 30+
  ];

  static Color getLevelColor(int level) {
    if (level < 5) return levelColors[0];
    if (level < 10) return levelColors[1];
    if (level < 20) return levelColors[2];
    if (level < 30) return levelColors[3];
    return levelColors[4];
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: const Color(0xFFFF6B6B),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(color: divider),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
          color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
          color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(
          color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
          color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        labelLarge: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme; // App uses dark theme primarily
}
