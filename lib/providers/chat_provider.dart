import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../services/task_templates.dart';
import '../services/user_scope.dart';
import '../config/constants.dart';
import '../config/strings.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  ChatProvider() {
    UserScope.changes.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    UserScope.changes.removeListener(_onUserChanged);
    super.dispose();
  }

  Future<void> _onUserChanged() async {
    // Wipe in-memory chat — next init() will load this user's history.
    _msgs = [];
    _pending = [];
    _typing = false;
    _error = null;
    notifyListeners();
    await init();
  }

  List<ChatMsg>        _msgs   = [];
  bool                 _typing = false;
  String?              _error;
  List<TaskSuggestion> _pending = [];
  bool                 _planCreatedSignal = false;

  List<ChatMsg>        get msgs    => List.unmodifiable(_msgs);
  bool                 get isTyping=> _typing;
  String?              get error   => _error;
  List<TaskSuggestion> get pending => _pending;

  /// Read-and-clear flag — true for one tick after AI auto-created a plan,
  /// so UI can trigger TaskProvider.loadAll().
  bool consumePlanCreatedSignal() {
    if (!_planCreatedSignal) return false;
    _planCreatedSignal = false;
    return true;
  }

  void updateToken(String? _) {}

  // ── INIT ──────────────────────────────────────────────
  Future<void> init() async {
    final saved = await _store.loadChat();
    if (saved.isEmpty) {
      _msgs = [_welcome()];
    } else {
      _msgs = saved.map(ChatMsg.fromJson).toList();
      // Eski suhbat bo'lsa yangi welcome qo'shmaymiz
    }
    notifyListeners();
  }

  ChatMsg _welcome() => ChatMsg(
    id:        'welcome_${DateTime.now().millisecondsSinceEpoch}',
    role:      'assistant',
    content:   S.get('chat_welcome'),
    timestamp: DateTime.now(),
  );

  // ── SEND ──────────────────────────────────────────────
  Future<void> send(String text,
      {Map<String, dynamic>? ctx}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMsg(
      id:        '${DateTime.now().microsecondsSinceEpoch}',
      role:      'user',
      content:   text.trim(),
      timestamp: DateTime.now(),
    );

    _msgs.add(userMsg);
    _typing  = true;
    _error   = null;
    _pending = [];
    notifyListeners();

    try {
      final history = _msgs
          .where((m) => m.id != userMsg.id)
          .toList()
          .reversed
          .take(8)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final res = await _api.post(
        K.aiChat,
        {
          'message': text.trim(),
          'conversation_history': history,
        },
        timeout: K.aiTimeout,
      );

      // Live backend: {"success":true, "data":{"message":..., "created_plan": {...}|null, "tokens_used":0}}
      final resData = res['data'] as Map<String, dynamic>? ?? res;
      String content = resData['message']?.toString() ??
          res['message']?.toString() ??
          S.tr('Javob olishda xato yuz berdi.', 'Произошла ошибка при получении ответа.', 'An error occurred while getting a response.');

      // Detect OpenAI quota error — show fallback template suggestions
      final isQuotaErr =
          content.toLowerCase().contains('quota') ||
              content.toLowerCase().contains('billing');
      List<TaskSuggestion>? fallbackTasks;
      if (isQuotaErr) {
        fallbackTasks = TaskTemplates.suggestFor(text);
        if (fallbackTasks.isEmpty) fallbackTasks = TaskTemplates.starter();
        content =
            S.tr('AI servisi vaqtincha ishlamayapti.', 'AI сервис временно недоступен.', 'AI service is temporarily unavailable.')
            + '\n\n'
            + S.tr('Siz uchun tayyor shablonlar tanladim — kerakli vazifalarni belgilang va qo\'shing.', 'Я подобрал готовые шаблоны — отметьте нужные задачи и добавьте.', 'I picked ready templates — mark the tasks you need and add them.');
      }

      // Case 1: backend auto-created a plan — reload tasks so they appear in dashboard
      final createdPlan = resData['created_plan'];
      bool planCreated = false;
      if (createdPlan is Map) {
        planCreated = true;
      }

      // Case 2: some builds may include explicit task suggestions
      List<TaskSuggestion>? tasks;
      final rawTasks = resData['suggested_tasks'] ?? res['suggested_tasks'];
      final rawPlanTasks = resData['plan_data'] is Map
          ? (resData['plan_data']['tasks'] as List?)
          : null;
      final taskList = rawTasks ?? rawPlanTasks;
      if (taskList is List && taskList.isNotEmpty) {
        tasks = taskList
            .map((t) => TaskSuggestion.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      // Apply fallback tasks when quota error
      tasks ??= fallbackTasks;

      if (planCreated) {
        content += S.get('plan_auto_created');
      }

      final aiMsg = ChatMsg(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
        tasks: tasks,
        isError: isQuotaErr,
      );

      _msgs.add(aiMsg);
      _pending = tasks ?? [];
      _planCreatedSignal = planCreated;
    } catch (e) {
      _error = e.toString();
      _msgs.add(ChatMsg(
        id:        'err_${DateTime.now().millisecondsSinceEpoch}',
        role:      'assistant',
        content:
            '❌ ${S.tr("Xato yuz berdi", "Произошла ошибка", "An error occurred")}: ${e.toString()}\n\n'
            '${S.tr("Qayta urinib ko\\'ring yoki internet aloqasini tekshiring.", "Попробуйте снова или проверьте интернет-соединение.", "Please retry or check your internet connection.")}',
        timestamp: DateTime.now(),
        isError:   true,
      ));
    }

    _typing = false;
    await _store.saveChat(_msgs.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  // ── CONFIRM AI TASKS ADDED (called by chat screen after TaskProvider success)
  Future<void> confirmAdded(int count) async {
    // Mark the most recent assistant message with un-added tasks as added,
    // so the selection panel disappears and stays gone across reloads.
    for (var i = _msgs.length - 1; i >= 0; i--) {
      final m = _msgs[i];
      if (m.isAssistant && m.hasTasks) {
        _msgs[i] = m.copyWith(tasksAdded: true);
        break;
      }
    }
    final confirmMsg = ChatMsg(
      id: 'confirm_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: S.get('tasks_added_thanks').replaceAll('{n}', '$count'),
      timestamp: DateTime.now(),
    );
    _msgs.add(confirmMsg);
    _pending = [];
    await _store.saveChat(_msgs.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  // Deprecated — kept for backward compat, now routes via TaskProvider externally
  Future<bool> addToDaily(List<TaskSuggestion> selected) async {
    if (selected.isEmpty) return false;
    await confirmAdded(selected.length);
    return true;
  }

  // ── CLEAR ─────────────────────────────────────────────
  void clearHistory() {
    _msgs    = [_welcome()];
    _pending = [];
    _store.clearChat();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
