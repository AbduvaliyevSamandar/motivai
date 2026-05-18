import 'package:flutter/material.dart';
import 'colors.dart';

class AppText {
  static TextStyle get displayLarge => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.txt,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.txt,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.txt,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.txt,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.txt,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.txt,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.txt,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.txt,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.txt,
      );

  static TextStyle get labelLarge => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.txt,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.txt,
      );
}
