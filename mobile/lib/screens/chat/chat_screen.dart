import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showSuggestions = true;

  final List<String> _suggestions = [
    '📋 Motivatsiya rejam tuzib ber',
    '🎓 Imtihonga tayyorgarlik rejasi',
    '💪 Kunlik sport + o\'qish rejasi',
    '🌍 Ingliz tili o\'rganish rejasi',
    '📊 Progressimni tahlil qil',
    '🔥 Meni rag\'batlantirib yuvor',
  ];

  // ===============================
  // Xabar jo'natish funksiyasi
  // ===============================
  void _send([String? text]) async {
    final msg = text ?? _ctrl.text;
    if (msg.trim().isEmpty) return;

    _ctrl.clear();
    setState(() => _showSuggestions = false);

    try {
      // quick-motivate API chaqiruvi
      final user = ref.read(userProvider);
      final response = await ref.read(apiServiceProvider).quickMotivate();
      if (response['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Xatolik yuz berdi'))
        );
        return; // boshqa oynaga o'tmaydi
      }
// else: muvaffaqiyatli bo‘lsa, boshqa oynaga o'tish mumkin);
      if (response['success'] != true) {
        final message = response['message'] ?? 'Xatolik yuz berdi';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message))
          );
        }
        return; // boshqa oynaga o'tmaydi
      }

      // Agar muvaffaqiyatli bo'lsa, chatga xabar qo'shamiz
      ref.read(chatProvider.notifier).sendMessage(msg);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik yuz berdi: $e'))
        );
      }
      return; // boshqa oynaga o'tmaydi
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    // Auto scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.messages.isNotEmpty) _scrollToBottom();
    });

    // Show plan created dialog
    if (state.planCreated != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPlanCreatedDialog(state.planCreated!);
        ref.read(chatProvider.notifier).clearPlanCreated();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('AI Motivator'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () {
              ref.read(chatProvider.notifier).startNewSession();
              setState(() => _showSuggestions = true);
            },
            tooltip: 'Yangi suhbat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: state.messages.isEmpty && _showSuggestions
                ? _WelcomeView(
              suggestions: _suggestions,
              onSuggestion: _send,
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length,
              itemBuilder: (_, i) {
                final msg = state.messages[i];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // Error
          if (state.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          // Input area
          _ChatInput(
            controller: _ctrl,
            isTyping: state.isTyping,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _showPlanCreatedDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'Reja yaratildi!',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '"${plan['title']}" rejangiz muvaffaqiyatli yaratildi.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Yoping'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/plans/${plan['id']}');
                      },
                      child: const Text('Ko\'rish'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Welcome view with suggestions
// ============================================
class _WelcomeView extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestion;

  const _WelcomeView({required this.suggestions, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Salom! Men MotivAI',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Maqsadlaringizni ayting va men sizga shaxsiy motivatsiya rejasi tuzib beraman!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tezkor savollar:',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => onSuggestion(s.substring(2).trim()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Message bubble
// ============================================
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppTheme.divider),
              ),
              child: message.isLoading
                  ? const _TypingIndicator()
                  : Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ============================================
// Typing indicator
// ============================================
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withOpacity(
              (i == 0 ? _anim.value : i == 1 ? (_anim.value * 0.8) : (_anim.value * 0.6))
                  .clamp(0.3, 1.0),
            ),
            shape: BoxShape.circle,
          ),
        ),
      )),

    );
  }
}

// ============================================
// Chat input
// ============================================
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final Function([String?]) onSend;

  const _ChatInput({
    required this.controller,
    required this.isTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Maqsadingizni yozing...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isTyping ? null : () => onSend(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isTyping
                    ? null
                    : const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                color: isTyping ? AppTheme.surface : null,
                shape: BoxShape.circle,
              ),
              child: isTyping
                  ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}