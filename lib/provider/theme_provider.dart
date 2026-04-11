import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
        await prefs.setBool('isDarkMode', false);
      } else {
        _themeMode = ThemeMode.dark;
        await prefs.setBool('isDarkMode', true);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling theme: $e');
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
