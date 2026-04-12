import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage.dart';
import '../config/constants.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  final _api   = Api();
  final _store = Storage();

  List<ChatMsg>       _msgs   = [];
  bool                _typing = false;
  String?             _error;
  List<TaskSuggestion>_pending= [];

  List<ChatMsg>        get msgs    => _msgs;
  bool                 get isTyping=> _typing;
  String?              get error   => _error;
  List<TaskSuggestion> get pending => _pending;

  void updateToken(String? _) {}

  static const _welcome = ChatMsg(
    id: 'w0', role: 'assistant',
    content: '👋 Salom! Men **MotivAI** — sizning shaxsiy sun\'iy intellekt motivatsion assistentingizman! 🚀\n\n'
        'Menda quyidagilarni so\'rashingiz mumkin:\n'
        '• 📋 Bugunlik motivatsiya rejasi\n'
        '• 🎯 Maqsadlaringizga mos vazifalar\n'
        '• 💪 Qiynalayotgan soha bo\'yicha maslahat\n'
        '• 🔥 Streak uzilmasligi uchun strategiya\n\n'
        'Nima haqida gaplashmoqchisiz?',
    timestamp: Duration.zero, // placeholder, real vaqt ishlatiladi
    isError: false,
  );

  Future<void> init() async {
    final saved = await _store.loadChat();
    if (saved.isEmpty) {
      _msgs = [_realWelcome()];
    } else {
      _msgs = saved.map(ChatMsg.fromJson).toList();
    }
    notifyListeners();
  }

  ChatMsg _realWelcome() => ChatMsg(
    id: 'welcome',
    role: 'assistant',
    content: '👋 Salom! Men **MotivAI** — sizning shaxsiy AI motivatsion assistentingizman! 🚀\n\n'
        'Quyidagilarni so\'rashingiz mumkin:\n'
        '• 📋 Bugunlik motivatsiya rejasi\n'
        '• 🎯 Maqsadlaringizga mos vazifalar\n'
        '• 💪 Qiynalayotgan soha bo\'yicha maslahat\n'
        '• 🔥 Streak uzilmasligi uchun strategiya\n\n'
        'Nima haqida gaplashmoqchisiz?',
    timestamp: DateTime.now(),
  );

  // ── SEND ──────────────────────────────────────────────
  Future<void> send(String text, {Map<String, dynamic>? ctx}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMsg(
      id: _uid(), role: 'user', content: text, timestamp: DateTime.now(),
    );
    _msgs.add(userMsg);
    _typing = true; _error = null; _pending = [];
    notifyListeners();

    try {
      // Oxirgi 8 xabar tarixi
      final history = _msgs
          .where((m) => m.id != userMsg.id)
          .toList().reversed.take(8).toList().reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final res = await _api.post(K.aiChat, {
        'message': text,
        'history': history,
        'user_context': ctx ?? {},
      }, timeout: K.aiTimeout);

      final aiMsg = ChatMsg(
        id: _uid(), role: 'assistant',
        content: (res['response'] ?? res['message'] ?? 'Javob olishda xato').toString(),
        timestamp: DateTime.now(),
        tasks: _parseTasks(res['suggested_tasks']),
      );
      _msgs.add(aiMsg);
      _pending = aiMsg.tasks ?? [];
    } catch (e) {
      _error = e.toString();
      _msgs.add(ChatMsg(
        id: _uid(), role: 'assistant',
        content: '❌ Xato: ${e.toString()}\n\nQayta urinib ko\'ring.',
        timestamp: DateTime.now(),
        isError: true,
      ));
    }

    _typing = false;
    await _store.saveChat(_msgs.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  // ── ADD SUGGESTED TASKS ───────────────────────────────
  Future<bool> addToDaily(List<TaskSuggestion> selected) async {
    try {
      await _api.post(K.fromChat, {
        'tasks': selected.map((t) => t.toJson()).toList(),
      });
      _msgs.add(ChatMsg(
        id: _uid(), role: 'assistant',
        content: '✅ ${selected.length} ta vazifa kunlik ro\'yxatingizga qo\'shildi!\n'
            'Ularni bajarganingizdan keyin belgilang va ball to\'plang! 💪',
        timestamp: DateTime.now(),
      ));
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

  void clearHistory() {
    _msgs = [_realWelcome()];
    _store.clearChat();
    notifyListeners();
  }

  List<TaskSuggestion>? _parseTasks(dynamic raw) {
    if (raw is! List) return null;
    return raw.map((t) => TaskSuggestion.fromJson(t as Map<String, dynamic>)).toList();
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();
}
