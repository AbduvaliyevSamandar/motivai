import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Writes app state to the Android home-screen widget storage so the
/// native widget can render the user's streak and next task.
class HomeWidgetService {
  static const _appId = 'uz.motivai.app';
  static const _providerName = 'MotivAiWidgetProvider';

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(_appId);
    } catch (_) {}
  }

  static Future<void> update({
    String? greeting,
    String? nextTaskTitle,
    int streak = 0,
    int tasksDone = 0,
    int tasksTotal = 0,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>(
          'greeting', greeting ?? 'MotivAI');
      await HomeWidget.saveWidgetData<String>(
          'nextTask',
          (nextTaskTitle == null || nextTaskTitle.isEmpty)
              ? 'Bugun sizni nima ruhlantiradi?'
              : nextTaskTitle);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<int>('tasksDone', tasksDone);
      await HomeWidget.saveWidgetData<int>('tasksTotal', tasksTotal);
      await HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );
    } catch (_) {}
  }
}
