import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  const TaskCard(
      {super.key,
      required this.task,
      required this.onComplete});

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
        vsync: this,
        duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t    = widget.task;
    final done = t.isCompleted;

    return ScaleTransition(
      scale: _scale,
      child: Opacity(
        opacity: done ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? C.border
                  : t.color.withOpacity(0.35),
              width: done ? 1 : 1.5,
            ),
          ),
          child: Column(children: [
            // Top color strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: done ? C.border : t.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(12)),
                  child: Center(child: Text(t.emoji,
                      style: const TextStyle(
                          fontSize: 22))),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: TextStyle(
                          color: done ? C.sub : C.txt,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      _Tag('⏱ ${t.durationMinutes}m', C.sub),
                      const SizedBox(width: 6),
                      _Tag(t.diffLabel,
                          _dc(t.difficulty)),
                      const SizedBox(width: 6),
                      _Tag('⭐ ${t.points}', C.gold),
                    ]),
                  ],
                )),
                const SizedBox(width: 8),
                // Complete btn
                GestureDetector(
                  onTapDown: (_) => _ctrl.forward(),
                  onTapUp: (_) async {
                    await _ctrl.reverse();
                    if (!done) widget.onComplete();
                  },
                  onTapCancel: () => _ctrl.reverse(),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: done
                          ? null
                          : const LinearGradient(
                              colors: C.gradPrimary),
                      color: done ? C.border : null,
                      shape: BoxShape.circle,
                      boxShadow: done
                          ? null
                          : [BoxShadow(
                              color: C.primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset:
                                  const Offset(0, 3))],
                    ),
                    child: Icon(
                      done
                          ? Icons.check
                          : Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ]),
            ),
            if (t.isFromChat)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    left: 14, right: 14, bottom: 10),
                child: Wrap(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: C.primary.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(6)),
                    child: const Text('🤖 AI tavsiyasi',
                        style: TextStyle(
                            color: C.primary,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w500))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Color _dc(String d) => {
    'easy':   const Color(0xFF43E97B),
    'medium': const Color(0xFFFFD700),
    'hard':   const Color(0xFFFFA726),
    'expert': const Color(0xFFEF5350),
  }[d] ?? C.sub;
}

class _Tag extends StatelessWidget {
  final String text;
  final Color  color;
  const _Tag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6)),
    child: Text(text,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500)));
}
