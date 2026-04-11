// lib/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5651D9);
  static const Color secondary = Color(0xFF43E97B);
  static const Color accent = Color(0xFFFF6584);
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF43E97B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFF7C59F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary,
  );
  
  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  
  // Spacing
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Nunito',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Nunito',
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(
          color: AppTheme.divider,
          width: 1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
