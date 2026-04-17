import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/theme.dart';
import '../../config/strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

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
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      'name': auth.name,
      'level': auth.level,
      'streak': auth.streak,
      'points': auth.points,
    });
    _toBottom();
  }

  Future<void> _addToTasks(List<TaskSuggestion> suggestions) async {
    final sel = suggestions.where((s) => s.isSelected).toList();
    if (sel.isEmpty) {
      _snack(S.get('error'), err: true);
      return;
    }
    final ok = await context.read<ChatProvider>().addToDaily(sel);
    if (ok && mounted) {
      await context.read<TaskProvider>().loadAll();
      _toBottom();
      _snack('${sel.length} ${S.get('task_added')}');
    } else {
      _snack(S.get('error'), err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? C.error : C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ]),
    );
  }

  // ── App Bar ───────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: C.surface,
      elevation: 0,
      titleSpacing: 16,
      title: Row(children: [
        // AI Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: C.gradPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: C.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text('AI', style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MotivAI Chat',
                style: TextStyle(
                  color: C.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Consumer<ChatProvider>(
                builder: (_, chat, __) => Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: chat.isTyping ? C.warning : C.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      chat.isTyping
                          ? S.get('ai_typing')
                          : S.get('done'),
                      style: TextStyle(
                        color: chat.isTyping ? C.warning : C.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: C.border),
          ),
          child: IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: C.sub, size: 20),
            onPressed: _clearConfirm,
            tooltip: S.get('clear_chat'),
          ),
        ),
      ],
    );
  }

  // ── Message List ──────────────────────────────────────
  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        _toBottom();
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          physics: const BouncingScrollPhysics(),
          itemCount: chat.msgs.length + (chat.isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == chat.msgs.length) {
              return const _TypingIndicator();
            }
            final m = chat.msgs[i];
            return Column(children: [
              _ChatBubble(msg: m),
              if (m.isAssistant && m.hasTasks)
                _TaskSuggestionPanel(
                  tasks: m.tasks!,
                  onAdd: _addToTasks,
                  onDecline: () => _snack(S.get('cancel')),
                ),
            ]);
          },
        );
      },
    );
  }

  // ── Input Bar ─────────────────────────────────────────
  Widget _buildInputBar() {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        final busy = chat.isTyping;
        return Container(
          decoration: BoxDecoration(
            color: C.surface,
            border: Border(top: BorderSide(color: C.border, width: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Quick prompts for first messages
            if (chat.msgs.length <= 1) _buildQuickPrompts(),

            // Input row
            Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: C.border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        enabled: !busy,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(color: C.txt, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: busy
                              ? S.get('ai_typing')
                              : S.get('type_message'),
                          hintStyle: TextStyle(
                            color: C.sub.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Send button
                  GestureDetector(
                    onTap: busy ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: busy
                              ? [C.border, C.border]
                              : C.gradPrimary,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: busy
                            ? null
                            : [
                                BoxShadow(
                                  color: C.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: busy
                            ? C.sub.withValues(alpha: 0.5)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── Quick Prompts ─────────────────────────────────────
  Widget _buildQuickPrompts() {
    final prompts = [
      ('🎯', S.get('ai_suggest')),
      ('💪', S.get('streak')),
      ('📚', S.get('tasks_label')),
      ('🔥', S.get('today_goal')),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        itemCount: prompts.length,
        itemBuilder: (_, i) {
          final p = prompts[i];
          return GestureDetector(
            onTap: () {
              _ctrl.text = p.$2;
              _send();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.$1, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  p.$2,
                  style: TextStyle(
                    color: C.txt,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Clear Confirmation ────────────────────────────────
  void _clearConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          S.get('clear_chat'),
          style: TextStyle(color: C.txt, fontWeight: FontWeight.bold),
        ),
        content: Text(
          S.get('clear_chat'),
          style: TextStyle(color: C.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'), style: TextStyle(color: C.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(context);
              _snack(S.get('chat_cleared'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.error,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('delete')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CHAT BUBBLE
// ═══════════════════════════════════════════════════════
class _ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final maxW = MediaQuery.of(context).size.width * 0.8;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Bubble
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: C.gradPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : msg.isError
                        ? C.error.withValues(alpha: 0.1)
                        : C.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.isError
                            ? C.error.withValues(alpha: 0.3)
                            : C.border,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? C.primary.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : C.txt,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
              child: Text(
                _formatTime(msg.timestamp),
                style: TextStyle(
                  color: C.sub.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════
//  TASK SUGGESTION PANEL
// ═══════════════════════════════════════════════════════
class _TaskSuggestionPanel extends StatefulWidget {
  final List<TaskSuggestion> tasks;
  final void Function(List<TaskSuggestion>) onAdd;
  final VoidCallback onDecline;

  const _TaskSuggestionPanel({
    required this.tasks,
    required this.onAdd,
    required this.onDecline,
  });

  @override
  State<_TaskSuggestionPanel> createState() => _TaskSuggestionPanelState();
}

class _TaskSuggestionPanelState extends State<_TaskSuggestionPanel> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.primary.withValues(alpha: 0.06),
            C.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: C.gradPrimary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.get('ai_suggest'),
                style: TextStyle(
                  color: C.txt,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: C.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.tasks.length}',
                style: TextStyle(
                  color: C.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // Task items
          ...widget.tasks.map((t) => _SuggestTaskItem(
                task: t,
                onToggle: () =>
                    setState(() => t.isSelected = !t.isSelected),
              )),

          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _done = true);
                  widget.onDecline();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.sub,
                  side: BorderSide(color: C.border),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(S.get('cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: C.gradPrimary),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: C.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onAdd(widget.tasks);
                    setState(() => _done = true);
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: Text(
                    S.get('add_task'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Suggest Task Item ───────────────────────────────────
class _SuggestTaskItem extends StatelessWidget {
  final TaskSuggestion task;
  final VoidCallback onToggle;

  const _SuggestTaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isSelected
              ? C.primary.withValues(alpha: 0.08)
              : C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isSelected
                ? C.primary.withValues(alpha: 0.4)
                : C.border,
            width: task.isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              task.isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(task.isSelected),
              color: task.isSelected ? C.primary : C.sub,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: C.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded,
                      color: C.sub, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${task.durationMinutes} min',
                    style: TextStyle(color: C.sub, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.star_rounded,
                      color: C.gold, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '~${task.estimatedPoints} ${S.get('points')}',
                    style: TextStyle(color: C.sub, fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TYPING INDICATOR
// ═══════════════════════════════════════════════════════
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: C.gradPrimary),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text('AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: C.primary.withValues(
                      alpha: 0.25 +
                          0.75 *
                              (((_ctrl.value + i * 0.3) % 1.0)),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            S.get('ai_typing'),
            style: TextStyle(
              color: C.sub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}
