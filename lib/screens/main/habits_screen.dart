import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../services/habit_storage.dart';
import '../../widgets/nebula/nebula.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await HabitStorage.load();
    if (mounted) setState(() {
      _habits = h;
      _loading = false;
    });
  }

  Future<void> _toggle(Habit h) async {
    HapticFeedback.selectionClick();
    await HabitStorage.toggleToday(h.id);
    _load();
  }

  Future<void> _addHabit() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<(String, String)?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddHabitSheet(),
    );
    if (result != null) {
      await HabitStorage.add(title: result.$1, emoji: result.$2);
      _load();
    }
  }

  Future<void> _delete(Habit h) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Odatni o\'chirish?',
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${h.title}" — ${h.completedDays.length} kunlik tarix yo\'qoladi.',
          style: GoogleFonts.poppins(color: AppColors.sub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Bekor qilish',
                style: GoogleFonts.poppins(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("O'chirish", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HabitStorage.remove(h.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: AppColors.gradCosmic),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 18),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: AppColors.titleGradient,
                        ).createShader(b),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'Kundalik odatlar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _habits.isEmpty
                          ? _empty()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: _habits.length,
                              itemBuilder: (_, i) => _HabitCard(
                                habit: _habits[i],
                                onToggle: () => _toggle(_habits[i]),
                                onDelete: () => _delete(_habits[i]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.secondary.withOpacity(0.1),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('\u{1F331}', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hali odat yo\'q',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kundalik odat qo\'shing — streak orttiring',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday();
    final streak = habit.currentStreak();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: Icon(Icons.delete_outline_rounded,
              color: AppColors.danger),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: done
                  ? LinearGradient(colors: [
                      AppColors.success.withOpacity(0.18),
                      AppColors.success.withOpacity(0.06),
                    ])
                  : null,
              color: done ? null : AppColors.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: done
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.border,
                width: done ? 1.5 : 1,
              ),
              boxShadow: done
                  ? [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(
                            colors: AppColors.gradSuccess)
                        : null,
                    color: done
                        ? null
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      habit.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('\u{1F525}',
                              style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            '$streak kun',
                            style: GoogleFonts.poppins(
                              color: AppColors.sub,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(
                            colors: AppColors.gradSuccess)
                        : null,
                    color: done
                        ? null
                        : AppColors.card.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        done ? Colors.white : AppColors.sub,
                    size: 22,
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

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet();
  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _ctrl = TextEditingController();
  String _emoji = '\u{1F3AF}';
  static const _emojis = [
    '\u{1F3AF}', '\u{1F4DA}', '\u{1F4AA}', '\u{1F9D8}',
    '\u{1F3C3}', '\u{1F4A7}', '\u{1F331}', '\u{1F3A8}',
    '\u{1F3B5}', '\u{1F373}', '\u{1F6CC}', '\u{1F4AC}',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Yangi odat',
            style: GoogleFonts.poppins(
              color: AppColors.txt,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _ctrl,
            label: 'Odat nomi',
            hint: 'Masalan: 30 daqiqa o\'qish',
            prefixIcon: Icons.edit_rounded,
          ),
          const SizedBox(height: 14),
          Text(
            'EMOJI',
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) {
              final sel = _emoji == e;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _emoji = e);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: AppColors.gradCosmic)
                        : null,
                    color: sel ? null : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          NebulaButton(
            label: "Qo'shish",
            icon: Icons.add_rounded,
            onTap: () {
              final t = _ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop<(String, String)?>(context, (t, _emoji));
            },
          ),
        ],
      ),
    );
  }
}
