// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_model.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _sessionId = const Uuid().v4();
  PlanModel? _lastCreatedPlan;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get sessionId => _sessionId;
  PlanModel? get lastCreatedPlan => _lastCreatedPlan;
  String? get error => _error;

  final ApiService _api = ApiService();

  void startNewSession() {
    _sessionId = const Uuid().v4();
    _messages = [];
    _lastCreatedPlan = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> sendMessage(String message) async {
    if (message.trim().isEmpty) return null;

    // Add user message immediately
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: message,
      sessionId: _sessionId,
    );
    _messages.add(userMsg);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build conversation history for API
      final history = _messages
          .where((m) => m.id != userMsg.id)
          .toList()           // <- bu yerda List ga aylantiramiz
          .takeLast(10)       // endi takeLast ishlaydi
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final res = await _api.sendChatMessage(
        message: message,
        sessionId: _sessionId,
        history: history,
      );

      if (res['success'] == true) {
        final data = res['data'];
        
        // Add AI response
        final aiMsg = ChatMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: data['message'],
          sessionId: _sessionId,
        );
        _messages.add(aiMsg);

        // Handle plan creation
        if (data['created_plan'] != null) {
          // Reload plan from API
          final planRes = await _api.getPlan(data['created_plan']['id']);
          _lastCreatedPlan = PlanModel.fromJson(planRes['data']['plan']);
        }

        _isLoading = false;
        notifyListeners();
        return data;
      }
    } catch (e) {
      _error = 'Xatolik yuz berdi. Internet aloqasini tekshiring.';
      final errMsg = ChatMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: '⚠️ Kechirasiz, hozir texnik muammo bor. Iltimos, biroz kutib qayta urinib ko\'ring.',
        sessionId: _sessionId,
      );
      _messages.add(errMsg);
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> loadHistory(String? sessionId) async {
    try {
      final res = await _api.getChatHistory(sessionId: sessionId);
      final msgs = (res['data']['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
      _messages = msgs;
      if (sessionId != null) _sessionId = sessionId;
      notifyListeners();
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  void clearLastPlan() {
    _lastCreatedPlan = null;
    notifyListeners();
  }
}

extension IterableExtension<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
