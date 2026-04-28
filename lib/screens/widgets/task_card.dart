import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../models/models.dart';
import 'task_detail_sheet.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool pinned;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.pinned = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final done = t.isCompleted;
    final overdue = t.isOverdue;
    final upcoming = t.isUpcomingSoon;

    final accent = done
        ? AppColors.border
        : overdue
            ? AppColors.danger
            : upcoming
                ? AppColors.accent
                : t.color;

    final card = ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: D.sp12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: overdue
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // ── Top color strip ──────────────────
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.border
                      : overdue
                          ? AppColors.danger
                          : upcoming
                              ? AppColors.accent
                              : t.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),
              // ── Content ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: t.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: D.sp12),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: GoogleFonts.poppins(
                                  color: done ? AppColors.sub : AppColors.txt,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Tag chips row
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (widget.pinned)
                                    _InfoTag(
                                      text: '\u{1F4CC} Pin',
                                      color: AppColors.accent,
                                    ),
                                  if (t.hasSchedule)
                                    _TimeTag(task: t),
                                  _InfoTag(
                                    text: '\u23F1 ${t.durationMinutes}m',
                                    color: AppColors.sub,
                                  ),
                                  _DifficultyBadge(difficulty: t.difficulty),
                                  _InfoTag(
                                    text: '\u2B50 ${t.points}',
                                    color: AppColors.accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: D.sp8),
                        // More menu (pin/edit/delete) — only for active tasks
                        if (!done && (widget.onEdit != null ||
                            widget.onDelete != null ||
                            widget.onPin != null))
                          _MoreMenu(
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onPin: widget.onPin,
                            pinned: widget.pinned,
                          ),
                        // Complete button
                        _CompleteButton(
                          done: done,
                          ctrl: _ctrl,
                          onComplete: widget.onComplete,
                        ),
                      ],
                    ),
                    // AI / overdue / upcoming badges
                    if (t.isFromChat || overdue || upcoming) ...[
                      const SizedBox(height: D.sp8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (overdue) const _OverdueBadge(),
                        if (upcoming) const _UpcomingBadge(),
                        if (t.isFromChat) _AiBadge(),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Tap anywhere (except buttons) opens detail sheet
    final tappable = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(D.radiusLg),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          showTaskDetail(
            context,
            widget.task,
            onComplete: done ? null : widget.onComplete,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          );
        },
        borderRadius: BorderRadius.circular(D.radiusLg),
        child: card,
      ),
    );

    // For active, non-completed tasks — wrap with Dismissible (swipe actions)
    if (!done && (widget.onDelete != null)) {
      return Dismissible(
        key: ValueKey('task_${widget.task.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.endToStart) {
            // Swipe left → delete
            widget.onDelete?.call();
            return false; // let the parent confirm dialog handle it
          } else if (dir == DismissDirection.startToEnd) {
            // Swipe right → complete
            widget.onComplete();
            return false;
          }
          return false;
        },
        background: _swipeBg(
          align: Alignment.centerLeft,
          color: AppColors.success,
          icon: LucideIcons.checkCircle2,
          label: 'Bajardim',
        ),
        secondaryBackground: _swipeBg(
          align: Alignment.centerRight,
          color: AppColors.danger,
          icon: LucideIcons.trash2,
          label: "O'chirish",
        ),
        child: tappable,
      );
    }

    return tappable;
  }

  Widget _swipeBg({
    required Alignment align,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: D.sp12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.12),
          ],
          begin: align == Alignment.centerLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: align == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      alignment: align,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MORE MENU
// ═══════════════════════════════════════════════════════════
class _MoreMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool pinned;
  const _MoreMenu({
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(LucideIcons.moreVertical,
            size: 16, color: AppColors.sub),
      ),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      itemBuilder: (_) => [
        if (onPin != null)
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(
                  pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  pinned ? 'Pinni yechish' : 'Pin qilish',
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.pencil,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Tahrirlash',
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 10),
                Text(
                  "O'chirish",
                  style: GoogleFonts.poppins(
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (v) {
        HapticFeedback.selectionClick();
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
        if (v == 'pin') onPin?.call();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  COMPLETE BUTTON
// ═══════════════════════════════════════════════════════════
class _CompleteButton extends StatelessWidget {
  final bool done;
  final AnimationController ctrl;
  final VoidCallback onComplete;

  const _CompleteButton({
    required this.done,
    required this.ctrl,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) async {
        await ctrl.reverse();
        if (!done) onComplete();
      },
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: done
              ? AppColors.success.withOpacity(0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? AppColors.success : AppColors.border,
            width: done ? 1 : 1.5,
          ),
        ),
        child: Icon(
          LucideIcons.check,
          color: done ? AppColors.success : AppColors.sub,
          size: 18,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DIFFICULTY BADGE
// ═══════════════════════════════════════════════════════════
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = _diffColor(difficulty);
    final label = _diffLabel(difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.sp8, vertical: D.sp4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(D.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _diffColor(String d) => {
        'easy': const Color(0xFF43E97B),
        'medium': const Color(0xFFFFD700),
        'hard': const Color(0xFFFFA726),
        'expert': const Color(0xFFEF5350),
      }[d] ??
      AppColors.sub;

  String _diffLabel(String d) => {
        'easy': S.get('easy'),
        'medium': S.get('medium'),
        'hard': S.get('hard'),
        'expert': S.get('expert'),
      }[d] ??
      d;
}

// ═══════════════════════════════════════════════════════════
//  INFO TAG
// ═══════════════════════════════════════════════════════════
class _InfoTag extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.sp8, vertical: D.sp4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(D.radiusSm),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TIME TAG (scheduled time)
// ═══════════════════════════════════════════════════════════
class _TimeTag extends StatelessWidget {
  final Task task;
  const _TimeTag({required this.task});

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final upcoming = task.isUpcomingSoon;
    final color = overdue
        ? AppColors.danger
        : upcoming
            ? AppColors.accent
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.08),
        ]),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue
                ? Icons.event_busy_rounded
                : upcoming
                    ? LucideIcons.bell
                    : LucideIcons.calendar,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            task.timeLabel,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  OVERDUE / UPCOMING BADGES
// ═══════════════════════════════════════════════════════════
class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.sp8, vertical: D.sp4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.danger.withOpacity(0.3),
          AppColors.accent.withOpacity(0.15),
        ]),
        borderRadius: BorderRadius.circular(D.radiusSm),
        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle,
              size: 12, color: AppColors.danger),
          const SizedBox(width: D.sp4),
          Text(
            'O\'tkazib yuborildi',
            style: GoogleFonts.poppins(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBadge extends StatefulWidget {
  const _UpcomingBadge();
  @override
  State<_UpcomingBadge> createState() => _UpcomingBadgeState();
}

class _UpcomingBadgeState extends State<_UpcomingBadge>
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
        padding:
            const EdgeInsets.symmetric(horizontal: D.sp8, vertical: D.sp4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.accent.withOpacity(0.25 + 0.15 * _ctrl.value),
            AppColors.primary.withOpacity(0.15),
          ]),
          borderRadius: BorderRadius.circular(D.radiusSm),
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.25 * _ctrl.value),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bell,
                size: 12, color: AppColors.accent),
            const SizedBox(width: D.sp4),
            Text(
              'Yaqinlashmoqda',
              style: GoogleFonts.poppins(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  AI BADGE
// ═══════════════════════════════════════════════════════════
class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.sp8, vertical: D.sp4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(D.radiusSm),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
          const SizedBox(width: D.sp4),
          Text(
            'AI',
            style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
