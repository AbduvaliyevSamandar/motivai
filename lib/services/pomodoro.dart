import 'dart:async';
import 'package:flutter/foundation.dart';

/// Simple Pomodoro state machine.
/// 25-min focus → 5-min short break → repeat → 15-min long break after 4 cycles.
class PomodoroSession extends ChangeNotifier {
  static const focusDuration = Duration(minutes: 25);
  static const shortBreak = Duration(minutes: 5);
  static const longBreak = Duration(minutes: 15);

  final String taskId;
  final String taskTitle;
  final DateTime startedAt = DateTime.now();

  PomodoroPhase _phase = PomodoroPhase.focus;
  int _cycle = 1;
  Duration _remaining = focusDuration;
  Timer? _tick;
  bool _paused = false;
  int _totalFocusedSeconds = 0;

  PomodoroSession({required this.taskId, required this.taskTitle}) {
    _start();
  }

  PomodoroPhase get phase => _phase;
  int get cycle => _cycle;
  Duration get remaining => _remaining;
  bool get isPaused => _paused;
  bool get isFocus => _phase == PomodoroPhase.focus;
  int get totalFocusedSeconds => _totalFocusedSeconds;
  int get totalFocusedMinutes => (_totalFocusedSeconds / 60).round();

  double get progress {
    final total = _phaseDuration(_phase).inSeconds;
    if (total == 0) return 0;
    return 1.0 - (_remaining.inSeconds / total);
  }

  String get phaseLabel {
    switch (_phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Qisqa dam';
      case PomodoroPhase.longBreak:
        return 'Uzoq dam';
    }
  }

  void _start() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      _remaining -= const Duration(seconds: 1);
      if (_phase == PomodoroPhase.focus) {
        _totalFocusedSeconds += 1;
      }
      if (_remaining.inSeconds <= 0) {
        _advancePhase();
      }
      notifyListeners();
    });
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    notifyListeners();
  }

  void togglePause() {
    _paused ? resume() : pause();
  }

  /// Skip to the next phase immediately.
  void skip() {
    _advancePhase();
    notifyListeners();
  }

  /// Abort the session — returns focused minutes so caller can log them.
  int stop() {
    _tick?.cancel();
    notifyListeners();
    return totalFocusedMinutes;
  }

  void _advancePhase() {
    if (_phase == PomodoroPhase.focus) {
      if (_cycle % 4 == 0) {
        _phase = PomodoroPhase.longBreak;
        _remaining = longBreak;
      } else {
        _phase = PomodoroPhase.shortBreak;
        _remaining = shortBreak;
      }
    } else {
      _phase = PomodoroPhase.focus;
      _remaining = focusDuration;
      _cycle += 1;
    }
  }

  Duration _phaseDuration(PomodoroPhase p) {
    switch (p) {
      case PomodoroPhase.focus:
        return focusDuration;
      case PomodoroPhase.shortBreak:
        return shortBreak;
      case PomodoroPhase.longBreak:
        return longBreak;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}

enum PomodoroPhase { focus, shortBreak, longBreak }
