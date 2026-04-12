import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _focus  = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    _ctrl.clear();
    await chat.send(text, ctx: {
      'name':   auth.name,
      'level':  auth.level,
      'streak': auth.streak,
      'points': auth.points,
    });
    _toBottom();
  }

  Future<void> _addToTasks(List<TaskSuggestion> suggestions) async {
    final selected = suggestions.where((s) => s.isSelected).toList();
    if (selected.isEmpty) {
      _snack('Hech narsa tanlanmagan', error: true);
      return;
    }
    final ok = await context.read<ChatProvider>().addToDaily(selected);
    if (ok) {
      await context.read<TaskProvider>().loadAll();
      _toBottom();
      _snack('✅ ${selected.length} ta vazifa qo\'shildi!');
    } else {
      _snack('Xato yuz berdi', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? C.error : C.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: _appBar(),
      body: Column(children: [
        Expanded(child: _msgList()),
        _inputBar(),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────
  AppBar _appBar() {
    return AppBar(
      backgroundColor: C.surface,
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: C.gradPrimary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MotivAI Chatbot',
              style: TextStyle(color: C.txt, fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Consumer<ChatProvider>(builder: (_, ch, __) => Text(
            ch.isTyping ? '✍️ Yozmoqda...' : '🟢 Tayyor',
            style: const TextStyle(color: C.success, fontSize: 11),
          )),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: C.sub),
          tooltip: 'Tarixni tozalash',
          onPressed: _confirmClear,
        ),
      ],
    );
  }

  // ── Message list ───────────────────────────────────────
  Widget _msgList() {
    return Consumer<ChatProvider>(builder: (_, chat, __) {
      final msgs = chat.msgs;
      _toBottom();
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: msgs.length + (chat.isTyping ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == msgs.length) return const _TypingDot();
          final m = msgs[i];
          return Column(children: [
            _Bubble(msg: m),
            if (m.isAssistant && m.hasTasks)
              _TaskPanel(tasks: m.tasks!, onAdd: _addToTasks),
          ]);
        },
      );
    });
  }

  // ── Input ──────────────────────────────────────────────
  Widget _inputBar() {
    return Consumer<ChatProvider>(builder: (_, chat, __) {
      final busy = chat.isTyping;
      return Container(
        decoration: const BoxDecoration(
          color: C.surface,
          border: Border(top: BorderSide(color: C.border, width: 0.8)),
        ),
        child: Column(children: [
          // Quick prompts — faqat birinchi kirganida
          if (chat.msgs.length <= 1) _QuickPrompts(onTap: (p) {
            _ctrl.text = p;
            _send();
          }),
          Padding(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  enabled: !busy,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: C.txt, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: busy ? 'AI yozmoqda...' : 'Maqsadingizni yozing...',
                    hintStyle: const TextStyle(color: C.sub, fontSize: 13),
                    filled: true,
                    fillColor: C.card,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: busy ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: busy
                        ? const LinearGradient(
                            colors: [C.border, C.border])
                        : const LinearGradient(colors: C.gradPrimary),
                    shape: BoxShape.circle,
                    boxShadow: busy ? null : [
                      BoxShadow(color: C.primary.withOpacity(0.4),
                          blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text('Tarixni tozalash',
            style: TextStyle(color: C.txt)),
        content: const Text('Barcha suhbat o\'chib ketadi.',
            style: TextStyle(color: C.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor', style: TextStyle(color: C.sub))),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: C.error,
                minimumSize: const Size(80, 36)),
            child: const Text("O'chirish")),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BUBBLE
// ═══════════════════════════════════════════════════════
class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: C.gradPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: isUser
                    ? null
                    : msg.isError
                        ? C.error.withOpacity(0.15)
                        : C.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: msg.isError
                    ? Border.all(color: C.error.withOpacity(0.4))
                    : !isUser
                        ? Border.all(color: C.border)
                        : null,
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : C.txt,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                _fmt(msg.timestamp),
                style: const TextStyle(color: C.sub, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ═══════════════════════════════════════════════════════
//  TASK SUGGESTION PANEL
// ═══════════════════════════════════════════════════════
class _TaskPanel extends StatefulWidget {
  final List<TaskSuggestion> tasks;
  final void Function(List<TaskSuggestion>) onAdd;
  const _TaskPanel({required this.tasks, required this.onAdd});
  @override
  State<_TaskPanel> createState() => _TaskPanelState();
}

class _TaskPanelState extends State<_TaskPanel> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    if (_added) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.primary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📋 ', style: TextStyle(fontSize: 16)),
          const Text('Tavsiya etilgan vazifalar',
              style: TextStyle(color: C.txt, fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const Spacer(),
          Text('${widget.tasks.length} ta',
              style: const TextStyle(color: C.sub, fontSize: 12)),
        ]),
        const SizedBox(height: 10),

        // Task list
        ...widget.tasks.map((t) => _SuggestItem(
              task: t,
              onToggle: () => setState(() => t.isSelected = !t.isSelected),
            )),

        const SizedBox(height: 12),

        // Buttons
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _added = true),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.sub,
                side: const BorderSide(color: C.border),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Yo'q, kerak emas"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onAdd(widget.tasks);
                setState(() => _added = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: C.primary,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('✅ Qo\'shish',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SuggestItem extends StatelessWidget {
  final TaskSuggestion task;
  final VoidCallback onToggle;
  const _SuggestItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: task.isSelected
              ? C.primary.withOpacity(0.1)
              : C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: task.isSelected
                ? C.primary.withOpacity(0.4)
                : C.border,
          ),
        ),
        child: Row(children: [
          Icon(
            task.isSelected
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            color: task.isSelected ? C.primary : C.sub,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(task.title,
                  style: const TextStyle(
                      color: C.txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Row(children: [
                _tiny('⏱ ${task.durationMinutes} daq'),
                const SizedBox(width: 8),
                _tiny('⭐ ~${task.estimatedPoints} ball'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tiny(String t) => Text(t,
      style: const TextStyle(color: C.sub, fontSize: 11));
}

// ═══════════════════════════════════════════════════════
//  TYPING INDICATOR
// ═══════════════════════════════════════════════════════
class _TypingDot extends StatefulWidget {
  const _TypingDot();
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🤖 ', style: TextStyle(fontSize: 14)),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: C.primary.withOpacity(0.3 + 0.7 * _ctrl.value),
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  QUICK PROMPTS
// ═══════════════════════════════════════════════════════
class _QuickPrompts extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickPrompts({required this.onTap});

  static const _prompts = [
    ('🎯', 'Bugunlik reja'),
    ('💪', 'Motivatsion maslahat'),
    ('📚', 'O\'quv vazifalar'),
    ('🔥', 'Streak saqlab qolish'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _prompts.map((p) => GestureDetector(
          onTap: () => onTap(p.$2),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.border),
            ),
            child: Row(children: [
              Text(p.$1, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(p.$2,
                  style: const TextStyle(color: C.txt, fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
