import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../models/models.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
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

    return ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: D.sp12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(D.radiusLg),
            border: Border.all(
              color: done
                  ? AppColors.border
                  : accent.withOpacity(overdue ? 0.6 : 0.35),
              width: done ? 1 : (overdue ? 1.8 : 1.5),
            ),
            boxShadow: done
                ? null
                : [
                    BoxShadow(
                      color: accent.withOpacity(overdue ? 0.25 : 0.1),
                      blurRadius: overdue ? 16 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // ── Top color strip ──────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? [AppColors.border, AppColors.border]
                        : overdue
                            ? [AppColors.danger, AppColors.accent]
                            : upcoming
                                ? [AppColors.accent, t.color]
                                : [t.color, t.color.withOpacity(0.6)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(D.radiusLg),
                    topRight: Radius.circular(D.radiusLg),
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
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: done
              ? null
              : const LinearGradient(colors: AppColors.gradPrimary),
          color: done ? AppColors.success.withOpacity(0.15) : null,
          shape: BoxShape.circle,
          boxShadow: done
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          Icons.check_rounded,
          color: done ? AppColors.success : Colors.white,
          size: 22,
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
                    ? Icons.notifications_active_rounded
                    : Icons.event_rounded,
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
          const Icon(Icons.error_outline_rounded,
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
            const Icon(Icons.notifications_active_rounded,
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
          const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
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
