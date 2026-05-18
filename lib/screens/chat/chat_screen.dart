import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';
import '../../widgets/voice_input_button.dart';

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
    // If AI auto-created a plan, refresh dashboard tasks
    if (mounted && chat.consumePlanCreatedSignal()) {
      await context.read<TaskProvider>().loadAll();
      if (mounted) {
        _snack(S.get('plan_created'));
      }
    }
    _toBottom();
  }

  Future<void> _addToTasks(List<TaskSuggestion> suggestions) async {
    final sel = suggestions.where((s) => s.isSelected).toList();
    if (sel.isEmpty) {
      _snack(S.get('select_at_least'), err: true);
      return;
    }
    HapticFeedback.mediumImpact();
    // Route through TaskProvider so tasks land in the unified list
    final tasks = context.read<TaskProvider>();
    final planId = await tasks.addSuggestions(suggestions: sel);

    if (planId != null && mounted) {
      // Add a confirmation message to chat
      await context.read<ChatProvider>().confirmAdded(sel.length);
      _toBottom();
      _snack(S.get('tasks_added_n').replaceAll('{n}', sel.length.toString()));
    } else {
      _snack(tasks.error ?? S.get('error'), err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle()),
        backgroundColor: err ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.magicpen,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MotivAI',
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Consumer<ChatProvider>(
                    builder: (_, chat, __) => Row(
                      children: [
                        _PulseDot(active: chat.isTyping),
                        const SizedBox(width: 6),
                        Text(
                          chat.isTyping
                              ? S.get('ai_typing')
                              : 'Online',
                          style: TextStyle(
                            color: AppColors.sub,
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
              icon: Icon(
                LucideIcons.trash2,
                color: AppColors.sub,
                size: 18,
              ),
              onPressed: _clearConfirm,
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          physics: const BouncingScrollPhysics(),
          itemCount: chat.msgs.length + (chat.isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == chat.msgs.length) return const _TypingIndicator();
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
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 4,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chat.msgs.length <= 1) _buildQuickPrompts(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focus,
                              enabled: !busy,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: TextStyle(
                                color: AppColors.txt,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: busy
                                    ? S.get('ai_typing')
                                    : S.get('type_message'),
                                hintStyle: TextStyle(
                                  color: AppColors.hint,
                                  fontSize: 13,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!busy)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: VoiceInputButton(controller: _ctrl),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: busy ? null : _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: busy ? AppColors.border : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: busy
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Icon(
                          LucideIcons.send,
                          color: busy
                              ? AppColors.sub.withOpacity(0.5)
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      ('', S.get('ai_suggest')),
      ('', S.get('streak')),
      ('', S.get('tasks_label')),
      ('\u{1F525}', S.get('today_goal')),
    ];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: prompts.length,
        itemBuilder: (_, i) {
          final p = prompts[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NebulaChip(
              label: p.$2,
              emoji: p.$1,
              onTap: () {
                _ctrl.text = p.$2;
                _send();
              },
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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          S.get('clear_chat'),
          style: TextStyle(
            color: AppColors.txt,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          S.get('clear_chat'),
          style: TextStyle(color: AppColors.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: TextStyle(color: AppColors.sub)),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(S.get('delete'), style: TextStyle()),
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
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.active ? AppColors.accent : AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.active ? AppColors.accent : AppColors.success)
                  .withOpacity(0.6 + 0.4 * _ctrl.value),
              blurRadius: 8 + 4 * _ctrl.value,
              spreadRadius: _ctrl.value * 1.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onPromptTap;
  const _EmptyChat({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    final prompts = [
      ('', S.tr('Bugun nima qilsam yaxshi?', 'Что мне сделать сегодня?', 'What should I do today?')),
      ('', S.tr('Meni motivatsiya qil', 'Замотивируй меня', 'Motivate me')),
      ('', S.tr('Matematika bo\'yicha vazifa ber', 'Дай задачу по математике', 'Give me a math task')),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Iconsax.magicpen,
                color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
              S.get('hi_im_motivai'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
        ),
        const SizedBox(height: 8),
        Text(
          S.get('how_can_i_help'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.sub,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 32),
        ...prompts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                onTap: () => onPromptTap(p.$2),
                child: Row(
                  children: [
                    Text(p.$1, style: const TextStyle(fontSize: 24),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.$2,
                        style: TextStyle(
                          color: AppColors.txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ),
                    Icon(LucideIcons.chevronRight,
                        color: AppColors.sub, size: 14),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CHAT BUBBLE
// ═══════════════════════════════════════════════════════════
class _ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final VoidCallback onDelete;
  const _ChatBubble({required this.msg, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final maxW = MediaQuery.of(context).size.width * 0.78;

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
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.magicpen,
                          color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MotivAI',
                      style: TextStyle(
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
              child: isUser ? _userBubble() : _aiBubble(),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 4, left: 6, right: 6),
              child: Text(
                _formatTime(msg.timestamp),
                style: TextStyle(
                  color: AppColors.sub.withOpacity(0.6),
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

  Widget _userBubble() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: _RichText(text: msg.content, color: Colors.white),
    );
  }

  Widget _aiBubble() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: msg.isError
                ? AppColors.danger.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(
              color: msg.isError
                  ? AppColors.danger.withOpacity(0.3)
                  : AppColors.glassBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: _RichText(text: msg.content, color: AppColors.txt),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.copy,
                  color: AppColors.primary),
              title: Text(
                S.get('copy'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.get('copied')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(
                S.get('delete'),
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _RichText extends StatelessWidget {
  final String text;
  final Color color;
  const _RichText({required this.text, required this.color});

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
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TASK SUGGESTION PANEL
// ═══════════════════════════════════════════════════════════
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
  bool _submitting = false;

  int get _selectedCount =>
      widget.tasks.where((t) => t.isSelected).length;
  int get _totalXP => widget.tasks
      .where((t) => t.isSelected)
      .fold<int>(0, (sum, t) => sum + t.estimatedPoints);
  int get _totalMinutes => widget.tasks
      .where((t) => t.isSelected)
      .fold<int>(0, (sum, t) => sum + t.durationMinutes);

  void _toggleAll(bool selectAll) {
    HapticFeedback.selectionClick();
    setState(() {
      for (final t in widget.tasks) {
        t.isSelected = selectAll;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final allSelected =
        widget.tasks.isNotEmpty && _selectedCount == widget.tasks.length;
    final anySelected = _selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 6),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title + count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.magicpen,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.get('dashboard_intro'),
                        style: TextStyle(
                          color: AppColors.txt,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        S.get('dashboard_pick_help'),
                        style: TextStyle(
                          color: AppColors.sub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    '${widget.tasks.length} ${S.get('remaining')}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Select all / none chips
            Row(
              children: [
                _selectChip(
                  label: S.get('select_all'),
                  icon: Icons.check_circle_outline_rounded,
                  active: allSelected,
                  onTap: () => _toggleAll(true),
                ),
                const SizedBox(width: 6),
                _selectChip(
                  label: S.tr('Tozalash', 'Очистить', 'Clear'),
                  icon: Icons.clear_all_rounded,
                  active: false,
                  onTap: () => _toggleAll(false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Task items
            ...widget.tasks.map((t) => _SuggestItem(
                  task: t,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    setState(() => t.isSelected = !t.isSelected);
                  },
                )),

            const SizedBox(height: 10),

            // Selection summary
            if (anySelected)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.star_1,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalXP XP',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule_rounded,
                        color: AppColors.sub, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_totalMinutes} ${S.tr('min', 'мин', 'min')}',
                      style: TextStyle(
                        color: AppColors.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    const Spacer(),
                    Text(
                      '$_selectedCount / ${widget.tasks.length}',
                      style: TextStyle(
                        color: AppColors.txt,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  ],
                ),
              ),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _done = true);
                            widget.onDecline();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sub,
                      side: BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      S.get('cancel_btn'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: NebulaButton(
                    label: anySelected
                        ? 'Qo\'shish ($_selectedCount)'
                        : S.get('select_task'),
                    icon: LucideIcons.plus,
                    height: 48,
                    disabled: !anySelected,
                    loading: _submitting,
                    onTap: () async {
                      if (_submitting) return;
                      setState(() => _submitting = true);
                      await Future<void>.delayed(
                          const Duration(milliseconds: 80));
                      widget.onAdd(widget.tasks);
                      if (!mounted) return;
                      setState(() {
                        _submitting = false;
                        _done = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withOpacity(0.22) : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14,
                    color: active
                        ? AppColors.primary
                        : AppColors.sub),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? AppColors.primary
                          : AppColors.sub,
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isSelected ? AppColors.primary.withOpacity(0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isSelected
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.border,
            width: task.isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              task.isSelected
                  ? LucideIcons.checkCircle2
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(task.isSelected),
              color: task.isSelected
                  ? AppColors.primary
                  : AppColors.sub,
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
                    color: AppColors.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded,
                      color: AppColors.sub, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${task.durationMinutes} ${S.tr('min', 'мин', 'min')}',
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  const SizedBox(width: 12),
                  Icon(Iconsax.star_1,
                      color: AppColors.accent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '~${task.estimatedPoints} XP',
                    style: TextStyle(
                        color: AppColors.sub, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis,
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

// ═══════════════════════════════════════════════════════════
//  TYPING INDICATOR
// ═══════════════════════════════════════════════════════════
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 8),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_ctrl.value + i * 0.22) % 1.0;
                    final scale =
                        0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.4 + 0.6 * scale),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withOpacity(0.4 * scale),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
