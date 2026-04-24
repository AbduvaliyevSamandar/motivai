import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';
import '../config/theme.dart';
import '../config/theme_presets.dart';
import '../config/strings.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'motivai_theme_dark';
  static const _langKey  = 'motivai_lang';
  static const _autoKey  = 'motivai_theme_auto';

  bool _isDark = true;
  bool _auto   = false;
  String _lang = 'uz';
  Timer? _autoTimer;

  bool   get isDark => _isDark;
  bool   get auto   => _auto;
  String get lang   => _lang;
  ThemeData get theme => _isDark ? AppTheme.dark : AppTheme.light;

  ThemeProvider() { _load(); }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool(_themeKey) ?? true;
    _auto   = p.getBool(_autoKey) ?? false;
    _lang   = p.getString(_langKey) ?? 'uz';
    if (_auto) _applyAutoMode();
    AppColors.setDark(_isDark);
    C.setDark(_isDark);
    S.setLang(_lang);
    await ThemePresets.load();
    if (_auto) _scheduleAutoTick();
    notifyListeners();
  }

  /// Set theme automatically based on clock hour: dark 19:00 -> 06:00.
  void _applyAutoMode() {
    final h = DateTime.now().hour;
    _isDark = h >= 19 || h < 6;
  }

  void _scheduleAutoTick() {
    _autoTimer?.cancel();
    // Re-check every 10 minutes. Cheap, catches sunrise/sunset without
    // needing a real astronomy calculation.
    _autoTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (!_auto) return;
      final wasDark = _isDark;
      _applyAutoMode();
      if (wasDark != _isDark) {
        AppColors.setDark(_isDark);
        C.setDark(_isDark);
        notifyListeners();
      }
    });
  }

  Future<void> setAuto(bool v) async {
    _auto = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_autoKey, v);
    if (v) {
      _applyAutoMode();
      AppColors.setDark(_isDark);
      C.setDark(_isDark);
      _scheduleAutoTick();
    } else {
      _autoTimer?.cancel();
    }
    notifyListeners();
  }

  /// Switch active color preset (ocean, forest, cyberpunk, pastel, mono, nebula).
  Future<void> setPreset(String id) async {
    await ThemePresets.set(id);
    notifyListeners();
  }

  String get presetId => ThemePresets.current.id;

  Future<void> toggle() async {
    _isDark = !_isDark;
    AppColors.setDark(_isDark);
    C.setDark(_isDark);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_themeKey, _isDark);
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    if (_isDark == v) return;
    _isDark = v;
    AppColors.setDark(v);
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
