import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../config/constants.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  List<ChatMsg>        _msgs   = [];
  bool                 _typing = false;
  String?              _error;
  List<TaskSuggestion> _pending = [];

  List<ChatMsg>        get msgs    => List.unmodifiable(_msgs);
  bool                 get isTyping=> _typing;
  String?              get error   => _error;
  List<TaskSuggestion> get pending => _pending;

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
    content:
        '👋 Salom! Men **MotivAI** — sizning AI motivatsion assistentingizman!\n\n'
        'Quyidagilarni so\'rashingiz mumkin:\n'
        '• 📋 Bugunlik yoki haftalik motivatsiya rejasi\n'
        '• 🎯 Qiziqishlaringizga mos vazifalar\n'
        '• 💪 Qiynalayotgan soha bo\'yicha maslahat\n'
        '• 🔥 Streak saqlash strategiyasi\n\n'
        'Nima haqida gaplashmoqchisiz?',
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
      // Oxirgi 8 xabar tarixi
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
          'message':      text.trim(),
          'history':      history,
          'user_context': ctx ?? {},
        },
        timeout: K.aiTimeout,
      );

      final content = res['response']?.toString() ??
          res['message']?.toString() ??
          'Javob olishda xato yuz berdi.';

      final rawTasks = res['suggested_tasks'];
      List<TaskSuggestion>? tasks;
      if (rawTasks is List && rawTasks.isNotEmpty) {
        tasks = rawTasks
            .map((t) => TaskSuggestion.fromJson(
                t as Map<String, dynamic>))
            .toList();
      }

      final aiMsg = ChatMsg(
        id:        '${DateTime.now().microsecondsSinceEpoch}',
        role:      'assistant',
        content:   content,
        timestamp: DateTime.now(),
        tasks:     tasks,
      );

      _msgs.add(aiMsg);
      _pending = tasks ?? [];
    } catch (e) {
      _error = e.toString();
      _msgs.add(ChatMsg(
        id:        'err_${DateTime.now().millisecondsSinceEpoch}',
        role:      'assistant',
        content:
            '❌ Xato yuz berdi: ${e.toString()}\n\n'
            'Qayta urinib ko\'ring yoki internet aloqasini tekshiring.',
        timestamp: DateTime.now(),
        isError:   true,
      ));
    }

    _typing = false;
    await _store.saveChat(_msgs.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  // ── ADD TASKS TO DAILY LIST ────────────────────────────
  Future<bool> addToDaily(List<TaskSuggestion> selected) async {
    if (selected.isEmpty) return false;
    try {
      await _api.post(K.fromChat, {
        'tasks': selected.map((t) => t.toJson()).toList(),
      });

      final confirmMsg = ChatMsg(
        id:        'confirm_${DateTime.now().millisecondsSinceEpoch}',
        role:      'assistant',
        content:
            '✅ Ajoyib! **${selected.length} ta vazifa** '
            'kunlik ro\'yxatingizga qo\'shildi!\n\n'
            'Ularni bajarib ball to\'plang va reytingda yuqorilang! 💪🏆',
        timestamp: DateTime.now(),
      );
      _msgs.add(confirmMsg);
      _pending = [];
      await _store.saveChat(_msgs.map((m) => m.toJson()).toList());
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
