import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
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
    final newBadges =
        (r['new_badges'] ?? r['new_achievements'] as List?) ?? [];

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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(D.sp24),
              border: Border.all(
                color: levelUp
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (levelUp ? AppColors.accent : AppColors.primary)
                      .withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Big Emoji --
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          levelUp ? AppColors.gradGold : AppColors.gradSuccess,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (levelUp ? AppColors.accent : AppColors.success)
                                .withValues(alpha: 0.3),
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
                const SizedBox(height: D.sp16),

                // -- Title --
                if (levelUp) ...[
                  ShaderMask(
                    shaderCallback: (r) =>
                        const LinearGradient(colors: AppColors.gradGold)
                            .createShader(r),
                    child: Text(
                      '${S.get('level_up')} $newLevel',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else
                  Text(
                    S.get('task_done'),
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 6),
                Text(
                  widget.taskTitle,
                  style: GoogleFonts.poppins(
                      color: AppColors.sub, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: D.sp24),

                // -- Stats Row --
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: D.sp16, horizontal: D.sp12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(D.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        emoji: '⭐',
                        value: '+$xpEarned',
                        label: S.get('points'),
                        color: AppColors.accent,
                      ),
                      _Divider(),
                      _StatColumn(
                        emoji: '🔥',
                        value: '$streak',
                        label: S.get('streak'),
                        color: const Color(0xFFFF6584),
                      ),
                      if (newLevel != null) ...[
                        _Divider(),
                        _StatColumn(
                          emoji: '🎯',
                          value: '$newLevel',
                          label: S.get('level'),
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),

                // -- Plan Progress --
                if (planProgress != null) ...[
                  const SizedBox(height: D.sp16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(D.sp12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(D.radiusMd),
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
                              style: GoogleFonts.poppins(
                                color: AppColors.txt,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${((planProgress is num ? planProgress : 0) * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: D.sp8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(D.sp4),
                          child: LinearProgressIndicator(
                            value: (planProgress is num
                                    ? planProgress.toDouble()
                                    : 0.0)
                                .clamp(0.0, 1.0),
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(
                                planCompleted
                                    ? AppColors.success
                                    : AppColors.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // -- New Achievements --
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: D.sp16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.12),
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
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
                              style: GoogleFonts.poppins(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...newBadges.map((a) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: D.sp4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (a is Map
                                            ? a['emoji']
                                            : null) ??
                                        '🎖',
                                    style:
                                        const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: D.sp8),
                                  Flexible(
                                    child: Text(
                                      (a is Map
                                              ? a['name']
                                              : a?.toString()) ??
                                          '',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.txt,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: D.sp24),

                // -- Continue Button --
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: levelUp
                            ? AppColors.gradGold
                            : AppColors.gradPrimary,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (levelUp
                                  ? AppColors.accent
                                  : AppColors.primary)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        S.get('continue_btn'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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

// ============================================================
//  STAT COLUMN
// ============================================================
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
        const SizedBox(height: D.sp4),
        Text(value,
            style: GoogleFonts.poppins(
              color: AppColors.txt,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.poppins(
                color: AppColors.sub, fontSize: 11)),
      ],
    );
  }
}

// ============================================================
//  DIVIDER
// ============================================================
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}
