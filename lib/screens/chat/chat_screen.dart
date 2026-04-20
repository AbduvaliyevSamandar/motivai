import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
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
    HapticFeedback.lightImpact();
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
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: err ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusMd),
        ),
        margin: const EdgeInsets.all(D.sp12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(D.sp16, D.sp8, D.sp12, D.sp12),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: D.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MotivAI Chat',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Consumer<ChatProvider>(
                      builder: (_, chat, __) => Row(
                        children: [
                          _PulseDot(active: chat.isTyping),
                          const SizedBox(width: 6),
                          Text(
                            chat.isTyping ? S.get('ai_typing') : 'Online',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
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
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.white, size: 18),
                ),
                onPressed: _clearConfirm,
                tooltip: S.get('clear_chat'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        _toBottom();
        if (chat.msgs.isEmpty && !chat.isTyping) {
          return _EmptyChat(onPromptTap: (p) {
            _ctrl.text = p;
            _send();
          });
        }
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(D.sp16, D.sp16, D.sp16, D.sp8),
          physics: const BouncingScrollPhysics(),
          itemCount: chat.msgs.length + (chat.isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == chat.msgs.length) {
              return const _TypingIndicator();
            }
            final m = chat.msgs[i];
            return Column(children: [
              _ChatBubble(
                msg: m,
                onDelete: () => chat.clearHistory(),
              ),
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

  Widget _buildInputBar() {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        final busy = chat.isTyping;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (chat.msgs.length <= 1) _buildQuickPrompts(),
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
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(D.sp24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        enabled: !busy,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: busy
                              ? S.get('ai_typing')
                              : S.get('type_message'),
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.sub.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: D.sp12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: busy ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: D.sp48,
                      height: D.sp48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: busy
                              ? [AppColors.border, AppColors.border]
                              : AppColors.gradPrimary,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: busy
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: busy
                            ? AppColors.sub.withOpacity(0.5)
                            : Colors.white,
                        size: D.iconMd,
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

  Widget _buildQuickPrompts() {
    final prompts = [
      ('\u{1F3AF}', S.get('ai_suggest')),
      ('\u{1F4AA}', S.get('streak')),
      ('\u{1F4DA}', S.get('tasks_label')),
      ('\u{1F525}', S.get('today_goal')),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: D.sp4),
        itemCount: prompts.length,
        itemBuilder: (_, i) {
          final p = prompts[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _ctrl.text = p.$2;
              _send();
            },
            child: Container(
              margin: const EdgeInsets.only(right: D.sp8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: D.sp8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.secondary.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.$1, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  p.$2,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
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

  void _clearConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusXl),
        ),
        title: Text(
          S.get('clear_chat'),
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          S.get('clear_chat'),
          style: GoogleFonts.poppins(color: AppColors.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: GoogleFonts.poppins(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(context);
              _snack(S.get('chat_cleared'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('delete'), style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0xFFFCD34D)
                : const Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.active
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF10B981))
                    .withOpacity(0.5 + 0.5 * _ctrl.value),
                blurRadius: 6 + 4 * _ctrl.value,
                spreadRadius: _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onPromptTap;
  const _EmptyChat({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    final prompts = [
      ('\u{1F3AF}', 'Bugun nima qilsam yaxshi?'),
      ('\u{1F4AA}', 'Meni motivatsiya qil'),
      ('\u{1F4DA}', 'Matematika bo\'yicha vazifa ber'),
    ];
    return ListView(
      padding: const EdgeInsets.all(D.sp24),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: D.sp20),
        Text(
          'Salom! Men MotivAI',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: D.sp8),
        Text(
          'Sizga qanday yordam bera olaman?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.sub,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: D.sp32),
        ...prompts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: D.sp12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(D.radiusMd),
                child: InkWell(
                  onTap: () => onPromptTap(p.$2),
                  borderRadius: BorderRadius.circular(D.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(D.sp16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(D.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(p.$1,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: D.sp12),
                        Expanded(
                          child: Text(
                            p.$2,
                            style: GoogleFonts.poppins(
                              color: AppColors.txt,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.sub, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

// ============================================================
//  CHAT BUBBLE
// ============================================================
class _ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final VoidCallback onDelete;
  const _ChatBubble({required this.msg, required this.onDelete});

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
            if (!isUser && !msg.isError)
              Padding(
                padding:
                    const EdgeInsets.only(left: D.sp4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradPrimary,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MotivAI',
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onLongPress: () => _showOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: D.sp16, vertical: D.sp12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: AppColors.gradPrimary,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser
                      ? null
                      : msg.isError
                          ? AppColors.danger.withOpacity(0.1)
                          : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isUser ? 18 : 4),
                    topRight: Radius.circular(isUser ? 4 : 18),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: msg.isError
                              ? AppColors.danger.withOpacity(0.3)
                              : AppColors.border,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppColors.primary.withOpacity(0.18)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _RichBubbleText(
                  text: msg.content,
                  color: isUser ? Colors.white : AppColors.txt,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: D.sp4, left: 6, right: 6),
              child: Text(
                _formatTime(msg.timestamp),
                style: GoogleFonts.poppins(
                  color: AppColors.sub.withOpacity(0.55),
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

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: D.sp16),
            ListTile(
              leading: const Icon(Icons.copy_rounded,
                  color: AppColors.primary),
              title: Text('Nusxa olish',
                  style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Nusxa olindi'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(
                S.get('delete'),
                style: GoogleFonts.poppins(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: D.sp8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

// Simple markdown-ish renderer: **bold** and `code`
class _RichBubbleText extends StatelessWidget {
  final String text;
  final Color color;
  const _RichBubbleText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    int last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final raw = m.group(0)!;
      if (raw.startsWith('**')) {
        spans.add(TextSpan(
          text: raw.substring(2, raw.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else {
        spans.add(TextSpan(
          text: raw.substring(1, raw.length - 1),
          style: GoogleFonts.firaCode(
            fontSize: 13,
            backgroundColor: color.withOpacity(0.08),
          ),
        ));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 14,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

// ============================================================
//  TASK SUGGESTION PANEL
// ============================================================
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
      margin: const EdgeInsets.only(bottom: 14, left: D.sp4),
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.gradPrimary),
                borderRadius: BorderRadius.circular(D.radiusSm),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: Colors.white, size: D.iconSm),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.get('ai_suggest'),
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: D.sp8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(D.radiusSm),
              ),
              child: Text(
                '${widget.tasks.length}',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: D.sp12),
          ...widget.tasks.map((t) => _SuggestTaskItem(
                task: t,
                onToggle: () =>
                    setState(() => t.isSelected = !t.isSelected),
              )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _done = true);
                  widget.onDecline();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sub,
                  side: BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(D.radiusMd),
                  ),
                ),
                child: Text(S.get('cancel'), style: GoogleFonts.poppins()),
              ),
            ),
            const SizedBox(width: D.sp12),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.gradPrimary),
                  borderRadius: BorderRadius.circular(D.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
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
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(D.radiusMd),
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
        margin: const EdgeInsets.only(bottom: D.sp8),
        padding: const EdgeInsets.all(D.sp12),
        decoration: BoxDecoration(
          color: task.isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(D.radiusMd),
          border: Border.all(
            color: task.isSelected
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
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
              color:
                  task.isSelected ? AppColors.primary : AppColors.sub,
              size: 22,
            ),
          ),
          const SizedBox(width: D.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: D.sp4),
                Row(children: [
                  Icon(Icons.schedule_rounded,
                      color: AppColors.sub, size: 12),
                  const SizedBox(width: D.sp4),
                  Text(
                    '${task.durationMinutes} min',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11),
                  ),
                  const SizedBox(width: D.sp12),
                  Icon(Icons.star_rounded,
                      color: AppColors.accent, size: 12),
                  const SizedBox(width: D.sp4),
                  Text(
                    '~${task.estimatedPoints} ${S.get('points')}',
                    style: GoogleFonts.poppins(
                        color: AppColors.sub, fontSize: 11),
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

// ============================================================
//  TYPING INDICATOR - 3 dot pulse
// ============================================================
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
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              gradient:
                  const LinearGradient(colors: AppColors.gradPrimary),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_ctrl.value + i * 0.22) % 1.0;
                final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3 + 0.7 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: D.sp8),
          Text(
            S.get('ai_typing'),
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}
