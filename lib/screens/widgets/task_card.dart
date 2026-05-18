import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

    // Difficulty drives the left accent stripe — calm color that reads
    // as priority signal without screaming. Things 3 / Apple Notes pattern.
    final accent = done
        ? AppColors.border
        : overdue
            ? AppColors.danger
            : upcoming
                ? AppColors.accent
                : _diffAccent(t.difficulty);

    final card = ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: D.sp12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: overdue
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ── Left accent stripe (4px, priority signal) ─────
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Column(children: [
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
                                style: TextStyle(
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
                                      text: S.get('title_pin'),
                                      color: AppColors.accent,
                                    ),
                                  if (t.hasSchedule)
                                    _TimeTag(task: t),
                                  _InfoTag(
                                    text: '\u23F1 ${t.durationMinutes}${S.tr('m', 'м', 'm')}',
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
                        // Action buttons cluster — both 32x32, gap 6, both
                        // top-aligned so they sit on the same baseline
                        // regardless of how tall the title column gets.
                        SizedBox(
                          height: 32,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!done && (widget.onEdit != null ||
                                  widget.onDelete != null ||
                                  widget.onPin != null)) ...[
                                _MoreMenu(
                                  onEdit: widget.onEdit,
                                  onDelete: widget.onDelete,
                                  onPin: widget.onPin,
                                  pinned: widget.pinned,
                                ),
                                const SizedBox(width: 6),
                              ],
                              _CompleteButton(
                                done: done,
                                ctrl: _ctrl,
                                onComplete: widget.onComplete,
                              ),
                            ],
                          ),
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
                ]),
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
          label: S.get('did_it'),
        ),
        secondaryBackground: _swipeBg(
          align: Alignment.centerRight,
          color: AppColors.danger,
          icon: LucideIcons.trash2,
          label: S.get('delete'),
        ),
        child: tappable,
      );
    }

    return tappable;
  }

  // Difficulty → calm priority color for the left accent stripe.
  Color _diffAccent(String d) {
    switch (d.toLowerCase()) {
      case 'easy':   return const Color(0xFF34D399); // green
      case 'hard':   return const Color(0xFFF87171); // red
      case 'expert': return const Color(0xFFA855F7); // purple
      default:       return AppColors.primary;       // medium → primary
    }
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: align,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
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
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        splashRadius: 16,
        offset: const Offset(0, 36),
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withOpacity(0.30), width: 1.5),
          ),
          child: Icon(Iconsax.more_copy,
              size: 18, color: AppColors.primary),
        ),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  pinned ? S.get('unpin_btn') : S.get('pin_btn'),
                  style: TextStyle(
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
                  S.get('edit_btn'),
                  style: TextStyle(
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
                  S.get('delete'),
                  style: TextStyle(
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
    // Apple Reminders style: empty 2px-stroked circle when active, filled
    // green circle with white check when complete. AnimatedSwitcher gives
    // a tiny pop on toggle so the button feels responsive.
    return GestureDetector(
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) async {
        await ctrl.reverse();
        if (!done) onComplete();
      },
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, anim) =>
            ScaleTransition(scale: anim, child: c),
        child: done
            // Done state: filled circle, bold tick-circle icon
            ? Container(
                key: const ValueKey('done'),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.tick_circle_copy,
                  color: Colors.white,
                  size: 22,
                ),
              )
            // Empty state: tinted circle with the same bold tick-circle
            // icon so the empty form already looks like a "tap to check"
            // affordance — no anonymous ring.
            : Container(
                key: const ValueKey('open'),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.45),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: AppColors.success.withOpacity(0.85),
                  size: 22,
                ),
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
            style: TextStyle(
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
          style: TextStyle(
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
            style: TextStyle(
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
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(D.radiusSm),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle,
              size: 12, color: AppColors.danger),
          const SizedBox(width: D.sp4),
          Text(
            S.get('skipped'),
            style: TextStyle(
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
          color: AppColors.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(D.radiusSm),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bell,
                size: 12, color: AppColors.accent),
            const SizedBox(width: D.sp4),
            Text(
              S.get('upcoming_label'),
              style: TextStyle(
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
        color: AppColors.primary.withOpacity(0.10),
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
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
