import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/local_schedules.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';

void showAddTaskDialog(BuildContext context, {Task? editTask}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTaskSheet(editTask: editTask),
  );
}

class _AddTaskSheet extends StatefulWidget {
  final Task? editTask;
  const _AddTaskSheet({this.editTask});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;

  late String _category;
  late String _difficulty;
  bool _loading = false;

  DateTime? _scheduledAt;
  int _reminderMinutes = 15;

  bool get _isEdit => widget.editTask != null;

  static const _categories = [
    ('study', '\u{1F4DA}', 'study'),
    ('exercise', '\u{1F4AA}', 'exercise'),
    ('reading', '\u{1F4D6}', 'reading'),
    ('meditation', '\u{1F9D8}', 'meditation'),
    ('social', '\u{1F465}', 'social'),
    ('creative', '\u{1F3A8}', 'creative'),
    ('productivity', '\u{26A1}', 'productivity'),
    ('challenge', '\u{1F3C6}', 'challenge'),
  ];

  static const _difficulties = [
    ('easy', Color(0xFF34D399)),
    ('medium', Color(0xFFFCD34D)),
    ('hard', Color(0xFFF59E0B)),
    ('expert', Color(0xFFF87171)),
  ];

  static const _reminderOptions = [5, 15, 30, 60, 120];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final t = widget.editTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _durationCtrl =
        TextEditingController(text: '${t?.durationMinutes ?? 30}');
    _category = t?.category ?? 'study';
    _difficulty = t?.difficulty ?? 'medium';
    _scheduledAt = t?.scheduledAt;
    _reminderMinutes = t?.reminderMinutes ?? 15;

    if (t == null) {
      // Pre-fill default reminder from settings only for new tasks
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final np = context.read<NotificationProvider>();
        setState(() => _reminderMinutes = np.defaultReminderMinutes);
      });
    }
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.card,
            onSurface: AppColors.txt,
          ),
          dialogBackgroundColor: AppColors.card,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _scheduledAt ?? now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.card,
            onSurface: AppColors.txt,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(DateTime d) {
    final now = DateTime.now();
    final sameDay = now.year == d.year && now.month == d.month && now.day == d.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = tomorrow.year == d.year &&
        tomorrow.month == d.month &&
        tomorrow.day == d.day;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Bugun, $hh:$mm';
    if (isTomorrow) return 'Ertaga, $hh:$mm';
    return '${d.day}/${d.month}/${d.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: AppColors.gradCosmic),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primary.withOpacity(0.4),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_task_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: AppColors.titleGradient,
                    ).createShader(b),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      _isEdit ? 'Vazifani tahrirlash' : S.get('add_task'),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _label(S.get('task_title')),
              const SizedBox(height: 6),
              GlassTextField(
                controller: _titleCtrl,
                hint: S.get('task_title'),
                prefixIcon: Icons.edit_rounded,
              ),
              const SizedBox(height: 14),
              _label(S.get('task_desc')),
              const SizedBox(height: 6),
              GlassTextField(
                controller: _descCtrl,
                hint: S.get('task_desc'),
                prefixIcon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 18),

              // ── SCHEDULE TIME ────────────────────────
              _label('Vaqt'),
              const SizedBox(height: 6),
              _timePickerTile(),

              // ── REMINDER (only if scheduled) ─────────
              if (_scheduledAt != null) ...[
                const SizedBox(height: 14),
                _label('Eslatma'),
                const SizedBox(height: 6),
                _reminderChips(),
              ],

              const SizedBox(height: 18),
              _label('Kategoriya'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  return NebulaChip(
                    label: S.get(c.$3),
                    emoji: c.$2,
                    selected: _category == c.$1,
                    onTap: () => setState(() => _category = c.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _label('Qiyinlik'),
              const SizedBox(height: 8),
              Row(
                children: _difficulties.map((d) {
                  final active = _difficulty == d.$1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: d.$1 != 'expert' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _difficulty = d.$1);
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 220),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: active
                                ? LinearGradient(colors: [
                                    d.$2.withOpacity(0.25),
                                    d.$2.withOpacity(0.08),
                                  ])
                                : null,
                            color: active ? null : AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? d.$2 : AppColors.border,
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: d.$2,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                S.get(d.$1),
                                style: GoogleFonts.poppins(
                                  color: active ? d.$2 : AppColors.sub,
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _label(S.get('duration')),
              const SizedBox(height: 6),
              GlassTextField(
                controller: _durationCtrl,
                hint: '30',
                prefixIcon: Icons.schedule_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              NebulaButton(
                label: _isEdit ? 'Saqlash' : S.get('add_task'),
                icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
                loading: _loading,
                onTap: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppColors.sub,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );

  Widget _timePickerTile() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _scheduledAt != null
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _scheduledAt != null
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.border,
                    width: _scheduledAt != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _scheduledAt != null
                          ? Icons.event_rounded
                          : Icons.schedule_rounded,
                      color: _scheduledAt != null
                          ? AppColors.primary
                          : AppColors.sub,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scheduledAt == null
                            ? 'Vaqt tanlash'
                            : _formatDateTime(_scheduledAt!),
                        style: GoogleFonts.poppins(
                          color: _scheduledAt != null
                              ? AppColors.txt
                              : AppColors.sub,
                          fontSize: 13,
                          fontWeight: _scheduledAt != null
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_scheduledAt != null) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _scheduledAt = null);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.close_rounded,
                    color: AppColors.danger.withOpacity(0.8), size: 18),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reminderChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        NebulaChip(
          label: 'Yo\'q',
          emoji: '\u{1F515}',
          selected: _reminderMinutes == 0,
          onTap: () => setState(() => _reminderMinutes = 0),
        ),
        ..._reminderOptions.map((m) {
          final label = m < 60 ? '$m min' : '${m ~/ 60} soat';
          return NebulaChip(
            label: label,
            emoji: '\u{1F514}',
            selected: _reminderMinutes == m,
            onTap: () => setState(() => _reminderMinutes = m),
          );
        }),
      ],
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Vazifa nomini kiriting', err: true);
      return;
    }
    setState(() => _loading = true);

    // EDIT MODE — update via TaskProvider
    if (_isEdit) {
      final t = widget.editTask!;
      try {
        final ok = await context.read<TaskProvider>().updateTask(
              taskId: t.id,
              planId: t.planId,
              title: title,
              description: _descCtrl.text.trim(),
              category: _category,
              difficulty: _difficulty,
              durationMinutes:
                  int.tryParse(_durationCtrl.text.trim()) ?? t.durationMinutes,
              xpReward: _diffPoints(_difficulty),
            );
        if (!mounted) return;
        if (_scheduledAt != null) {
          await LocalSchedules.saveById(
            taskId: t.id,
            scheduledAt: _scheduledAt!,
            reminderMinutes: _reminderMinutes,
          );
          if (_reminderMinutes > 0 && mounted) {
            await context.read<NotificationProvider>().scheduleTaskReminder(
                  taskId: t.id,
                  taskTitle: title,
                  scheduledAt: _scheduledAt!,
                  reminderMinutes: _reminderMinutes,
                );
          }
        } else {
          await LocalSchedules.remove(t.id);
        }
        if (!mounted) return;
        if (ok) {
          await context.read<TaskProvider>().loadAll();
          if (!mounted) return;
          Navigator.pop(context);
          _toast('Yangilandi');
        } else {
          setState(() => _loading = false);
          _toast(context.read<TaskProvider>().error ?? "Xatolik",
              err: true);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        _toast('Xatolik: $e', err: true);
      }
      return;
    }

    // CREATE MODE — use TaskProvider.createTask which does optimistic insert
    try {
      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 30;
      final points = _diffPoints(_difficulty);

      final ok = await context.read<TaskProvider>().createTask(
            title: title,
            description: _descCtrl.text.trim(),
            category: _category,
            difficulty: _difficulty,
            durationMinutes: duration,
            xpReward: points,
            scheduledAt: _scheduledAt,
            reminderMinutes: _reminderMinutes,
          );

      if (!mounted) return;
      if (!ok) {
        setState(() => _loading = false);
        _toast(
          'Xatolik: ${context.read<TaskProvider>().error ?? "Server javob bermadi"}',
          err: true,
        );
        return;
      }

      // Schedule local reminder (no-op on web)
      if (_scheduledAt != null && _reminderMinutes > 0) {
        final notifs = context.read<NotificationProvider>();
        await notifs.scheduleTaskReminder(
          taskId: 'new_${DateTime.now().millisecondsSinceEpoch}',
          taskTitle: title,
          scheduledAt: _scheduledAt!,
          reminderMinutes: _reminderMinutes,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      _toast("Vazifa qo'shildi");
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Xatolik: ${e.toString()}', err: true);
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(err ? Icons.error_outline : Icons.check_circle_rounded,
            color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.poppins(color: Colors.white))),
      ]),
      backgroundColor: err ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
    ));
  }

  int _diffPoints(String d) => {
        'easy': 20,
        'medium': 50,
        'hard': 80,
        'expert': 120,
      }[d] ??
      50;
}
