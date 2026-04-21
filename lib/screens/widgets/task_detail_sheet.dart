import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';

void showTaskDetail(
  BuildContext context,
  Task task, {
  VoidCallback? onComplete,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskDetailSheet(
      task: task,
      onComplete: onComplete,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

class _TaskDetailSheet extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TaskDetailSheet({
    required this.task,
    this.onComplete,
    this.onEdit,
    this.onDelete,
  });

  Color get _accent => task.isOverdue
      ? AppColors.danger
      : task.isUpcomingSoon
          ? AppColors.accent
          : task.color;

  List<Color> get _gradient {
    if (task.isOverdue) return [AppColors.danger, AppColors.accent];
    if (task.isUpcomingSoon) return [AppColors.accent, AppColors.primary];
    return [task.color, task.color.withOpacity(0.6)];
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            const SizedBox(height: 20),

            // Emoji + Category badge row
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(task.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: task.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (task.isFromChat) ...[
                            _miniBadge('AI', AppColors.primary,
                                Icons.auto_awesome_rounded),
                            const SizedBox(width: 6),
                          ],
                          if (task.isOverdue)
                            _miniBadge("O'tkazilgan",
                                AppColors.danger, Icons.error_outline_rounded)
                          else if (task.isUpcomingSoon)
                            _miniBadge('Yaqinlashmoqda',
                                AppColors.accent, Icons.notifications_active_rounded)
                          else if (task.isCompleted)
                            _miniBadge('Bajarilgan',
                                AppColors.success, Icons.check_circle_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              task.title,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),

            // Description
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Details grid
            _detailsSection(),

            // Plan info
            if (task.planTitle != null && task.planTitle!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 16, color: AppColors.sub),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.planTitle!,
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            if (!task.isCompleted) ...[
              NebulaButton(
                label: 'Bajardim',
                icon: Icons.check_rounded,
                onTap: onComplete == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        onComplete!();
                      },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                      child: _secondaryBtn(
                        icon: Icons.edit_outlined,
                        label: 'Tahrirlash',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          onEdit!();
                        },
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 10),
                  if (onDelete != null)
                    Expanded(
                      child: _secondaryBtn(
                        icon: Icons.delete_outline_rounded,
                        label: "O'chirish",
                        color: AppColors.danger,
                        onTap: () {
                          Navigator.pop(context);
                          onDelete!();
                        },
                      ),
                    ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.success.withOpacity(0.22),
                    AppColors.success.withOpacity(0.08),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu vazifa bajarilgan',
                        style: GoogleFonts.poppins(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (task.completedAt != null)
                      Text(
                        _relCompleted(task.completedAt!),
                        style: GoogleFonts.poppins(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSection() {
    return Column(
      children: [
        _detailRow(
          Icons.star_rounded,
          AppColors.accent,
          'XP',
          '+${task.points}',
        ),
        const SizedBox(height: 10),
        _detailRow(
          Icons.schedule_rounded,
          AppColors.info,
          'Davomiyligi',
          '${task.durationMinutes} daqiqa',
        ),
        const SizedBox(height: 10),
        _detailRow(
          _diffIcon(task.difficulty),
          _diffColor(task.difficulty),
          'Qiyinligi',
          task.diffLabel,
        ),
        if (task.hasSchedule) ...[
          const SizedBox(height: 10),
          _detailRow(
            Icons.event_rounded,
            AppColors.primary,
            'Vaqt',
            task.timeLabel,
          ),
          if (task.reminderMinutes > 0) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.notifications_active_rounded,
              AppColors.pink,
              'Eslatma',
              '${task.reminderMinutes} daqiqa oldin',
            ),
          ],
        ],
      ],
    );
  }

  Widget _detailRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.txt,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _secondaryBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _diffIcon(String d) => {
        'easy': Icons.flash_on_rounded,
        'medium': Icons.fitness_center_rounded,
        'hard': Icons.local_fire_department_rounded,
        'expert': Icons.workspace_premium_rounded,
      }[d] ??
      Icons.label_rounded;

  Color _diffColor(String d) => {
        'easy': const Color(0xFF34D399),
        'medium': const Color(0xFFFCD34D),
        'hard': const Color(0xFFF59E0B),
        'expert': const Color(0xFFF87171),
      }[d] ??
      AppColors.sub;

  String _relCompleted(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    return '${diff.inDays} kun oldin';
  }
}
