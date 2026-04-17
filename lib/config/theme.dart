import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Backward-compatible alias delegating to [AppColors].
class C {
  static bool get isDark => AppColors.isDark;
  static void setDark(bool v) => AppColors.setDark(v);

  // Brand
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const secondary = AppColors.secondary;
  static const accent = AppColors.accent;
  static const success = AppColors.success;
  static const danger = AppColors.danger;
  static const info = AppColors.info;

  // Legacy aliases
  static const primaryLight = AppColors.secondary;
  static const gold = AppColors.accent;
  static const teal = AppColors.info;
  static const warning = AppColors.accent;
  static const error = AppColors.danger;

  // Theme-aware
  static Color get bg => AppColors.bg;
  static Color get surface => AppColors.surface;
  static Color get card => AppColors.card;
  static Color get border => AppColors.border;
  static Color get divider => AppColors.divider;
  static Color get txt => AppColors.txt;
  static Color get sub => AppColors.sub;
  static Color get hint => AppColors.hint;

  // Gradients
  static const gradPrimary = AppColors.gradPrimary;
  static const gradSuccess = AppColors.gradSuccess;
  static const gradWarning = AppColors.gradWarning;
  static const gradGold = AppColors.gradGold;
  static const gradAccent = AppColors.gradAccent;
  static const gradGreen = AppColors.gradSuccess;

  // Category
  static const cat = AppColors.cat;
}

/// Provides full [ThemeData] for dark & light modes.
class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FD);
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final card = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final txt = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E1B4B);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final hint = isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: txt,
      displayColor: txt,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer:
            isDark ? const Color(0xFF2D2460) : const Color(0xFFEDE9FE),
        onSecondaryContainer: isDark ? Colors.white : AppColors.secondary,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        surface: surface,
        onSurface: txt,
        surfaceContainerHighest: card,
        error: AppColors.danger,
        onError: Colors.white,
        outline: borderColor,
        outlineVariant:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: txt,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txt,
        ),
        iconTheme: IconThemeData(color: txt, size: 24),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: TextStyle(color: sub),
        hintStyle: TextStyle(color: hint),
        prefixIconColor: sub,
        suffixIconColor: sub,
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: sub,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF334155) : txt,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txt,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: sub,
        ),
      ),
      dividerColor: borderColor,
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
        thickness: 1,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
