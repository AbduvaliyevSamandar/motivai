import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/strings.dart';

class CompletionDialog extends StatefulWidget {
  final Map<String, dynamic> result;
  final String taskTitle;

  const CompletionDialog({
    super.key,
    required this.result,
    required this.taskTitle,
  });

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    final xpEarned = r['xp_earned'] ?? r['points_earned'] ?? 0;
    final newXp = r['new_xp'] ?? r['total_xp'] ?? 0;
    final newLevel = r['new_level'] ?? r['level'];
    final levelUp = r['level_up'] == true;
    final streak = r['current_streak'] ?? r['streak'] ?? 0;
    final planProgress = r['plan_progress'];
    final planCompleted = r['plan_completed'] == true;
    final newBadges = (r['new_badges'] ?? r['new_achievements'] as List?) ?? [];

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: levelUp
                    ? C.gold.withOpacity(0.5)
                    : C.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (levelUp ? C.gold : C.primary).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Big Emoji ──────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: levelUp ? C.gradGold : C.gradGreen,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (levelUp ? C.gold : C.success)
                            .withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      levelUp ? '🚀' : '✅',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ──────────────────────────────
                if (levelUp) ...[
                  ShaderMask(
                    shaderCallback: (r) =>
                        const LinearGradient(colors: C.gradGold)
                            .createShader(r),
                    child: Text(
                      '${S.get('level_up')} $newLevel',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else
                  Text(
                    S.get('task_done'),
                    style: TextStyle(
                        color: C.txt,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 6),
                Text(
                  widget.taskTitle,
                  style: TextStyle(color: C.sub, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                // ── Stats Row ──────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        emoji: '⭐',
                        value: '+$xpEarned',
                        label: S.get('points'),
                        color: C.gold,
                      ),
                      _Divider(),
                      _StatColumn(
                        emoji: '🔥',
                        value: '$streak',
                        label: S.get('streak'),
                        color: C.accent,
                      ),
                      if (newLevel != null) ...[
                        _Divider(),
                        _StatColumn(
                          emoji: '🎯',
                          value: '$newLevel',
                          label: S.get('level'),
                          color: C.primary,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Plan Progress ──────────────────────
                if (planProgress != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              planCompleted
                                  ? S.get('all_done')
                                  : S.get('today_goal'),
                              style: TextStyle(
                                  color: C.txt,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${((planProgress is num ? planProgress : 0) * 100).toInt()}%',
                              style: TextStyle(
                                  color: C.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (planProgress is num
                                    ? planProgress.toDouble()
                                    : 0.0)
                                .clamp(0.0, 1.0),
                            backgroundColor: C.border,
                            valueColor: AlwaysStoppedAnimation(
                                planCompleted ? C.success : C.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── New Achievements ───────────────────
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          C.gold.withOpacity(0.12),
                          C.gold.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: C.gold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🏆',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              S.get('achievements'),
                              style: TextStyle(
                                  color: C.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...newBadges.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (a is Map
                                            ? a['emoji']
                                            : null) ??
                                        '🎖',
                                    style: const TextStyle(
                                        fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      (a is Map
                                              ? a['name']
                                              : a?.toString()) ??
                                          '',
                                      style: TextStyle(
                                          color: C.txt,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Continue Button ────────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: levelUp ? C.gradGold : C.gradPrimary,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (levelUp ? C.gold : C.primary)
                              .withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        S.get('continue_btn'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
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
//  STAT COLUMN
// ═══════════════════════════════════════════════════════════
class _StatColumn extends StatelessWidget {
  final String emoji, value, label;
  final Color color;

  const _StatColumn({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: C.txt,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: C.sub, fontSize: 11)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DIVIDER
// ═══════════════════════════════════════════════════════════
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: C.border,
    );
  }
}
