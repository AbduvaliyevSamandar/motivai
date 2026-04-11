import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// ===== USER PROVIDER =====
class UserState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  UserState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final ApiService _api;

  UserNotifier(this._api) : super(const UserState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final user = StorageService.getUser();
    final isLoggedIn = StorageService.isLoggedIn();
    state = state.copyWith(user: user, isLoggedIn: isLoggedIn);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login(email: email, password: password);
      final data = res['data'];
      await StorageService.saveToken(data['access_token']);
      await StorageService.saveRefreshToken(data['refresh_token']);
      await StorageService.saveUser(data['user']);
      state = state.copyWith(
        user: data['user'],
        isLoggedIn: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String lang) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.register(
        name: name, email: email, password: password, language: lang);
      final data = res['data'];
      await StorageService.saveToken(data['access_token']);
      await StorageService.saveRefreshToken(data['refresh_token']);
      await StorageService.saveUser(data['user']);
      state = state.copyWith(
        user: data['user'],
        isLoggedIn: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.getMe();
      final user = res['data']['user'];
      await StorageService.saveUser(user);
      state = state.copyWith(user: user);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> logout() async {
    await StorageService.clearAuth();
    state = const UserState();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('409')) return 'Bu email allaqachon ro\'yxatdan o\'tgan';
    if (e.toString().contains('401')) return 'Email yoki parol noto\'g\'ri';
    return 'Xatolik yuz berdi. Iltimos qayta urinib ko\'ring.';
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return UserNotifier(api);
});

// ===== CHAT PROVIDER =====
class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? sessionId;
  final String? error;
  final Map<String, dynamic>? planCreated;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.sessionId,
    this.error,
    this.planCreated,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? sessionId,
    String? error,
    Map<String, dynamic>? planCreated,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      sessionId: sessionId ?? this.sessionId,
      error: error,
      planCreated: planCreated,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api;

  ChatNotifier(this._api) : super(const ChatState()) {
    _initSession();
  }

  void _initSession() {
    final savedSession = StorageService.getLastSession();
    if (savedSession != null) {
      state = state.copyWith(sessionId: savedSession);
      loadHistory(savedSession);
    }
  }

  Future<void> loadHistory(String sessionId) async {
    try {
      final res = await _api.getChatHistory(sessionId: sessionId);
      final msgs = (res['data']['messages'] as List).map((m) => ChatMessage(
        id: m['id'] ?? UniqueKey().toString(),
        role: m['role'],
        content: m['content'],
        timestamp: DateTime.parse(m['timestamp']),
      )).toList();
      state = state.copyWith(messages: msgs, sessionId: sessionId);
    } catch (e) {
      // Start fresh
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: 'loading',
      role: 'assistant',
      content: '...',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isTyping: true,
      error: null,
      planCreated: null,
    );

    try {
      // Build conversation history for context
      final history = state.messages
          .where((m) => !m.isLoading && m.id != userMsg.id)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final res = await _api.chat(
        message: text,
        sessionId: state.sessionId,
        conversationHistory: history,
      );

      final data = res['data'];
      final sessionId = data['session_id'] ?? state.sessionId;

      if (sessionId != null) {
        await StorageService.saveLastSession(sessionId);
      }

      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai',
        role: 'assistant',
        content: data['message'],
        timestamp: DateTime.now(),
      );

      final updatedMessages = state.messages
          .where((m) => m.id != 'loading')
          .toList()
        ..add(aiMsg);

      state = state.copyWith(
        messages: updatedMessages,
        isTyping: false,
        sessionId: sessionId,
        planCreated: data['plan_created'],
      );
    } catch (e) {
      final updatedMessages = state.messages.where((m) => m.id != 'loading').toList();
      state = state.copyWith(
        messages: updatedMessages,
        isTyping: false,
        error: 'AI bilan bog\'lanishda xatolik. Iltimos qayta urinib ko\'ring.',
      );
    }
  }

  void clearPlanCreated() {
    state = state.copyWith(planCreated: null);
  }

  void startNewSession() {
    state = const ChatState();
    StorageService.saveLastSession('');
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ChatNotifier(api);
});

// ===== PLANS PROVIDER =====
class PlansState {
  final List<dynamic> plans;
  final bool isLoading;
  final String? error;

  const PlansState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
  });

  PlansState copyWith({
    List<dynamic>? plans,
    bool? isLoading,
    String? error,
  }) => PlansState(
    plans: plans ?? this.plans,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class PlansNotifier extends StateNotifier<PlansState> {
  final ApiService _api;

  PlansNotifier(this._api) : super(const PlansState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getPlans();
      state = state.copyWith(
        plans: res['data']['plans'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Rejalar yuklanmadi');
    }
  }

  Future<Map<String, dynamic>?> completeTask({
    required String planId,
    required String taskId,
    int studyMinutes = 0,
  }) async {
    try {
      final res = await _api.completeTask(
        planId: planId,
        taskId: taskId,
        studyMinutes: studyMinutes,
      );
      await load(); // Refresh
      return res['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> deletePlan(String planId) async {
    try {
      await _api.deletePlan(planId);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final plansProvider = StateNotifierProvider<PlansNotifier, PlansState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PlansNotifier(api);
});

// ===== LEADERBOARD PROVIDER =====
final leaderboardProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getLeaderboard(period: period);
  return res['data'];
});

// ===== USER STATS PROVIDER =====
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getUserStats();
  return res['data'];
});

// ===== PROGRESS PROVIDER =====
final progressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getProgressSummary();
  return res['data'];
});

// Needed for ChatMessage import
class UniqueKey {
  @override
  String toString() => DateTime.now().microsecondsSinceEpoch.toString();
}
