import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Backward-compatible alias.
class C {
  static bool get isDark => AppColors.isDark;
  static void setDark(bool v) => AppColors.setDark(v);

  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const secondary = AppColors.secondary;
  static const accent = AppColors.accent;
  static const success = AppColors.success;
  static const danger = AppColors.danger;
  static const info = AppColors.info;
  static const primaryLight = AppColors.secondary;
  static const gold = AppColors.accent;
  static const teal = AppColors.info;
  static const warning = AppColors.accent;
  static const error = AppColors.danger;

  static Color get bg => AppColors.bg;
  static Color get surface => AppColors.surface;
  static Color get card => AppColors.card;
  static Color get border => AppColors.border;
  static Color get divider => AppColors.divider;
  static Color get txt => AppColors.txt;
  static Color get sub => AppColors.sub;
  static Color get hint => AppColors.hint;

  static const gradPrimary = AppColors.gradPrimary;
  static const gradSuccess = AppColors.gradSuccess;
  static const gradWarning = AppColors.gradWarning;
  static const gradGold = AppColors.gradGold;
  static const gradAccent = AppColors.gradAccent;
  static const gradGreen = AppColors.gradSuccess;
  static const cat = AppColors.cat;
}

/// Nebula Premium ThemeData
class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF08091A) : const Color(0xFFF7F6FB);
    final surface =
        isDark ? const Color(0xFF111327) : const Color(0xFFFFFFFF);
    final card = isDark ? const Color(0xFF161933) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF252847) : const Color(0xFFE5E3F0);
    final txt = isDark ? const Color(0xFFF1F1FA) : const Color(0xFF0F1028);
    final sub = isDark ? const Color(0xFFA5A8C7) : const Color(0xFF6B6E8F);
    final hint = isDark ? const Color(0xFF6C6F8E) : const Color(0xFFA5A8C7);

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
        onTertiary: const Color(0xFF0F1028),
        surface: surface,
        onSurface: txt,
        surfaceContainerHighest: card,
        error: AppColors.danger,
        onError: Colors.white,
        outline: borderColor,
        outlineVariant: isDark
            ? const Color(0xFF1A1D36)
            : const Color(0xFFF0EEF7),
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
          fontWeight: FontWeight.w700,
          color: txt,
        ),
        iconTheme: IconThemeData(color: txt, size: 24),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.danger, width: 2),
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
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: sub,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: GoogleFonts.poppins(
          color: txt,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: txt,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: sub,
        ),
      ),
      dividerColor: borderColor,
      dividerTheme: DividerThemeData(
        color: isDark
            ? const Color(0xFF1A1D36)
            : const Color(0xFFF0EEF7),
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
