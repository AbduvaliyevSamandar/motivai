// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/plan_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showSuggestions = true;

  final List<String> _suggestions = [
    "Menga dasturlash bo'yicha 30 kunlik reja tuz",
    "Imtihonga tayyorlanishga yordam ber",
    "Ingliz tilini o'rganish rejasi kerak",
    "Bugun motivatsiyam past, nima qilay?",
    "Haftalik o'qish rejasini tuzib ber",
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    setState(() => _showSuggestions = false);
    
    final chat = context.read<ChatProvider>();
    final result = await chat.sendMessage(text);
    _scrollToBottom();

    // If plan was created, show dialog
    if (result != null && chat.lastCreatedPlan != null && mounted) {
      _showPlanCreatedDialog(chat.lastCreatedPlan!);
    }
  }

  void _showPlanCreatedDialog(PlanModel plan) {
    chat_p() => context.read<ChatProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Reja yaratildi!', style: AppTheme.heading2),
            const SizedBox(height: 8),
            Text(plan.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('${plan.tasks.length} ta vazifa | ${plan.durationDays} kun',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<PlanProvider>().addAIPlan(plan);
                  context.read<ChatProvider>().clearLastPlan();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Rejalarni ko'rish"),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.read<ChatProvider>().clearLastPlan();
                Navigator.pop(ctx);
              },
              child: const Text("Keyinroq"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MotivAI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Onlayn', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              chat.startNewSession();
              setState(() => _showSuggestions = true);
            },
            tooltip: "Yangi suhbat",
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chat.messages.isEmpty
                ? _buildWelcome(user?.name ?? 'Talaba')
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = chat.messages[i];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),

          // Suggestions
          if (_showSuggestions && chat.messages.isEmpty)
            Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _sendMessage(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (chat.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.aiGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🤖', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  const Text('MotivAI yozmoqda...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      )),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'AI bilan suhbatlashing...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        onSubmitted: (v) => _sendMessage(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_textCtrl.text),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.aiGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 20),
            Text('Salom, $name!', style: AppTheme.heading2),
            const SizedBox(height: 10),
            const Text(
              'Men MotivAI — sizning shaxsiy AI yordamchingizman. '
              'Maqsadlaringizni ayting va men sizga aniq reja tuzib beraman!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quyidagi takliflardan birini bosib boshlang 👇',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
