import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'motivai_theme_dark';
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeData get theme => _isDark ? AppTheme.dark : AppTheme.light;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_key) ?? true;
    C.setDark(_isDark);
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    C.setDark(_isDark);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, _isDark);
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    if (_isDark == v) return;
    _isDark = v;
    C.setDark(v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
    notifyListeners();
  }
}
