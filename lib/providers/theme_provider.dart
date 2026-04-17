import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/strings.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'motivai_theme_dark';
  static const _langKey  = 'motivai_lang';

  bool _isDark = true;
  String _lang = 'uz';

  bool   get isDark => _isDark;
  String get lang   => _lang;
  ThemeData get theme => _isDark ? AppTheme.dark : AppTheme.light;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_themeKey) ?? true;
    _lang   = p.getString(_langKey) ?? 'uz';
    C.setDark(_isDark);
    S.setLang(_lang);
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    C.setDark(_isDark);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_themeKey, _isDark);
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    if (_isDark == v) return;
    _isDark = v;
    C.setDark(v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_themeKey, v);
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    if (_lang == lang) return;
    _lang = lang;
    S.setLang(lang);
    final p = await SharedPreferences.getInstance();
    await p.setString(_langKey, lang);
    notifyListeners();
  }
}
