import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../services/api.dart';
import '../../config/constants.dart';
import '../../providers/task_provider.dart';

/// Show the add-task modal bottom sheet
void showAddTaskDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');

  String _category = 'study';
  String _priority = 'medium';
  String _difficulty = 'medium';
  bool _loading = false;

  static const _categories = [
    'study',
    'exercise',
    'reading',
    'meditation',
    'social',
    'creative',
    'productivity',
    'challenge',
  ];

  static const _categoryEmojis = {
    'study': '\u{1F4DA}',
    'exercise': '\u{1F4AA}',
    'reading': '\u{1F4D6}',
    'meditation': '\u{1F9D8}',
    'social': '\u{1F465}',
    'creative': '\u{1F3A8}',
    'productivity': '\u26A1',
    'challenge': '\u{1F3C6}',
  };

  static const _priorities = ['low', 'medium', 'high', 'urgent'];
  static const _difficulties = ['easy', 'medium', 'hard', 'expert'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(D.sp24, D.sp12, D.sp24, D.sp24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ──────────────────────────
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
              const SizedBox(height: D.sp20),

              // ── Title ───────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradPrimary),
                      borderRadius: BorderRadius.circular(D.radiusMd),
                    ),
                    child: const Icon(Icons.add_task_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: D.sp12),
                  Text(
                    S.get('add_task'),
                    style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: D.sp24),

              // ── Task Title Field ────────────────────
              _buildLabel(S.get('task_title')),
              const SizedBox(height: D.sp8),
              _buildTextField(
                controller: _titleCtrl,
                hint: S.get('task_title'),
                icon: Icons.edit_rounded,
              ),
              const SizedBox(height: 18),

              // ── Task Description Field ──────────────
              _buildLabel(S.get('task_desc')),
              const SizedBox(height: D.sp8),
              _buildTextField(
                controller: _descCtrl,
                hint: S.get('task_desc'),
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 18),

              // ── Category Dropdown ───────────────────
              _buildLabel(S.get('category')),
              const SizedBox(height: D.sp8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.sub),
                    style: GoogleFonts.poppins(
                        color: AppColors.txt, fontSize: 14),
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(_categoryEmojis[c] ?? '\u{1F4CC}',
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(c[0].toUpperCase() + c.substring(1),
                                style: GoogleFonts.poppins(
                                    color: AppColors.txt, fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Priority Selector ───────────────────
              _buildLabel(S.get('priority')),
              const SizedBox(height: D.sp8),
              _buildChipSelector(
                items: _priorities,
                selected: _priority,
                colors: {
                  'low': AppColors.success,
                  'medium': AppColors.accent,
                  'high': const Color(0xFFFFA726),
                  'urgent': AppColors.danger,
                },
                labels: {
                  'low': S.get('low'),
                  'medium': S.get('medium'),
                  'high': S.get('high'),
                  'urgent': S.get('urgent'),
                },
                onSelect: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 18),

              // ── Difficulty Selector ─────────────────
              _buildLabel('${S.get('easy')} / ${S.get('medium')} / ${S.get('hard')} / ${S.get('expert')}'),
              const SizedBox(height: D.sp8),
              _buildChipSelector(
                items: _difficulties,
                selected: _difficulty,
                colors: {
                  'easy': const Color(0xFF43E97B),
                  'medium': const Color(0xFFFFD700),
                  'hard': const Color(0xFFFFA726),
                  'expert': const Color(0xFFEF5350),
                },
                labels: {
                  'easy': S.get('easy'),
                  'medium': S.get('medium'),
                  'hard': S.get('hard'),
                  'expert': S.get('expert'),
                },
                onSelect: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 18),

              // ── Duration Field ──────────────────────
              _buildLabel(S.get('duration')),
              const SizedBox(height: D.sp8),
              _buildTextField(
                controller: _durationCtrl,
                hint: '30',
                icon: Icons.schedule_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),

              // ── Submit Button ───────────────────────
              GestureDetector(
                onTap: _loading ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.gradPrimary),
                    borderRadius: BorderRadius.circular(D.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: D.sp8),
                              Text(
                                S.get('add_task'),
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: D.sp12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
          color: AppColors.sub, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: AppColors.txt, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              color: AppColors.hint.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppColors.sub, size: D.iconMd),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required String selected,
    required Map<String, Color> colors,
    required Map<String, String> labels,
    required ValueChanged<String> onSelect,
  }) {
    return Row(
      children: items.map((item) {
        final isActive = item == selected;
        final color = colors[item] ?? AppColors.sub;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: item != items.last ? D.sp8 : 0),
              padding: const EdgeInsets.symmetric(vertical: D.sp12),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(D.radiusMd),
                border: Border.all(
                  color: isActive
                      ? color.withOpacity(0.5)
                      : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  labels[item] ?? item,
                  style: GoogleFonts.poppins(
                    color: isActive ? color : AppColors.sub,
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.get('task_title')),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _loading = true);

    try {
      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 30;
      final points = _difficultyPoints(_difficulty);

      await Api().post(K.plans, {
        'title': title,
        'description': _descCtrl.text.trim(),
        'goal': title,
        'category': _category,
        'duration_days': 1,
        'tasks': [
          {
            'title': title,
            'description': _descCtrl.text.trim(),
            'category': _category,
            'difficulty': _difficulty,
            'duration_minutes': duration,
            'xp_reward': points,
          },
        ],
        'milestones': [],
        'reminder_enabled': true,
        'visibility': 'private',
      });

      if (!mounted) return;
      context.read<TaskProvider>().loadAll();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: D.iconMd),
            const SizedBox(width: D.sp8),
            Text(S.get('task_added')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(D.radiusMd)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _difficultyPoints(String d) => {
        'easy': 20,
        'medium': 50,
        'hard': 80,
        'expert': 120,
      }[d] ??
      50;
}
