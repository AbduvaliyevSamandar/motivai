import 'package:flutter/material.dart';
import '../../config/theme.dart';
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

    return ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done ? C.border : t.color.withOpacity(0.3),
              width: done ? 1 : 1.5,
            ),
            boxShadow: done
                ? null
                : [
                    BoxShadow(
                      color: t.color.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Left color strip ──────────────────
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: done ? C.border : t.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                // ── Content ──────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: emoji + title + complete button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji container
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: t.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(t.emoji,
                                    style:
                                        const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title + description
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: TextStyle(
                                      color: done ? C.sub : C.txt,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (t.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      t.description,
                                      style: TextStyle(
                                          color: C.sub, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Complete button
                            _CompleteButton(
                              done: done,
                              ctrl: _ctrl,
                              onComplete: widget.onComplete,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom row: tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Duration
                            _InfoTag(
                              icon: Icons.schedule_rounded,
                              text: '${t.durationMinutes}m',
                              color: C.sub,
                            ),
                            // Difficulty badge
                            _DifficultyBadge(difficulty: t.difficulty),
                            // Points
                            _InfoTag(
                              icon: Icons.star_rounded,
                              text: '${t.points} ${S.get('points')}',
                              color: C.gold,
                            ),
                            // AI badge
                            if (t.isFromChat)
                              _AiBadge(),
                          ],
                        ),
                      ],
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: done
              ? null
              : const LinearGradient(colors: C.gradPrimary),
          color: done ? C.success.withOpacity(0.15) : null,
          shape: BoxShape.circle,
          boxShadow: done
              ? null
              : [
                  BoxShadow(
                    color: C.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          done ? Icons.check_rounded : Icons.check_rounded,
          color: done ? C.success : Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
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
      C.sub;

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
  final IconData icon;
  final String text;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.primary.withOpacity(0.15),
            C.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: C.primary),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
                color: C.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
