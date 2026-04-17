import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../widgets/task_card.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/add_task_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final h = DateTime.now().hour;
    final greet = h < 12
        ? S.get('good_morning')
        : h < 18
            ? S.get('good_day')
            : S.get('good_evening');

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: _buildFAB(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await tasks.loadAll();
          await auth.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient Header ──────────────────────────
            SliverToBoxAdapter(
              child: _GradientHeader(
                greet: greet,
                name: auth.name,
                level: auth.level,
                points: auth.points,
                streak: auth.streak,
                emoji: auth.levelEmoji,
                totalTasks: auth.totalTasks,
              ),
            ),

            // ── Stats Row ────────────────────────────────
            SliverToBoxAdapter(
              child: _StatsRow(
                points: auth.points,
                level: auth.level,
                streak: auth.streak,
                tasksDone: tasks.completedToday,
              ),
            ),

            // ── Progress Card ────────────────────────────
            SliverToBoxAdapter(
              child: _ProgressCard(
                done: tasks.completedToday,
                total: tasks.totalToday,
                progress: tasks.dailyProgress,
              ),
            ),

            // ── Loading ──────────────────────────────────
            if (tasks.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: D.sp16),
                        Text(S.get('loading'),
                            style: GoogleFonts.poppins(
                                color: AppColors.sub, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // ── Today Tasks Section Header ─────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(D.sp20, D.sp8, D.sp20, D.sp8),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(D.sp8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.today_rounded,
                          color: AppColors.primary, size: D.iconMd),
                    ),
                    const SizedBox(width: 10),
                    Text(S.get('today_tasks'),
                        style: GoogleFonts.poppins(
                            color: AppColors.txt,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tasks.dailyProgress >= 1.0
                              ? AppColors.gradSuccess
                              : AppColors.gradPrimary,
                        ),
                        borderRadius: BorderRadius.circular(D.radiusMd),
                      ),
                      child: Text(
                        '${tasks.completedToday}/${tasks.totalToday}',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Task List or Empty State ───────────────
              if (tasks.daily.isEmpty)
                SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: D.sp16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => TaskCard(
                        task: tasks.daily[i],
                        onComplete: () =>
                            _complete(context, tasks, tasks.daily[i]),
                      ),
                      childCount: tasks.daily.length,
                    ),
                  ),
                ),

              // ── AI Suggestions Section ─────────────────
              if (tasks.recommended.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(D.sp20, D.sp24, D.sp20, D.sp8),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(D.sp8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.gradAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: D.iconMd),
                      ),
                      const SizedBox(width: 10),
                      Text(S.get('ai_suggest'),
                          style: GoogleFonts.poppins(
                              color: AppColors.txt,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: D.sp16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => TaskCard(
                        task: tasks.recommended[i],
                        onComplete: () => _complete(
                            context, tasks, tasks.recommended[i]),
                      ),
                      childCount: tasks.recommended.length,
                    ),
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradPrimary),
        borderRadius: BorderRadius.circular(D.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => showAddTaskDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(S.get('add_task'),
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _complete(
      BuildContext ctx, TaskProvider tasks, Task task) async {
    if (task.isCompleted) return;
    final res = await tasks.complete(task.id, planId: task.planId);
    if (!ctx.mounted) return;
    if (res != null) {
      await ctx.read<AuthProvider>().refresh();
      if (!ctx.mounted) return;
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) =>
            CompletionDialog(result: res, taskTitle: task.title),
      );
    } else if (tasks.error != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(tasks.error!),
        backgroundColor: AppColors.danger,
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  GRADIENT HEADER
// ═══════════════════════════════════════════════════════════
class _GradientHeader extends StatelessWidget {
  final String greet, name, emoji;
  final int level, points, streak, totalTasks;

  const _GradientHeader({
    required this.greet,
    required this.name,
    required this.emoji,
    required this.level,
    required this.points,
    required this.streak,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.08),
            AppColors.bg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(D.sp20, D.sp16, D.sp20, D.sp20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greet,
                            style: GoogleFonts.poppins(
                                color: AppColors.sub,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: D.sp4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name.isNotEmpty ? name : 'User',
                                style: GoogleFonts.poppins(
                                    color: AppColors.txt,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: D.sp8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: D.sp4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.gradPrimary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emoji,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: D.sp4),
                                  Text(
                                    '${S.get('level')} $level',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: D.sp12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradAccent),
                      borderRadius: BorderRadius.circular(D.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('\u{1F525}',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('$streak',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(S.get('day'),
                            style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATS ROW
// ═══════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final int points, level, streak, tasksDone;

  const _StatsRow({
    required this.points,
    required this.level,
    required this.streak,
    required this.tasksDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.sp16),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            iconColor: AppColors.accent,
            value: '$points',
            label: S.get('points'),
            gradColors: AppColors.gradGold,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.primary,
            value: '$level',
            label: S.get('level'),
            gradColors: AppColors.gradPrimary,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accent,
            value: '$streak',
            label: S.get('streak'),
            gradColors: AppColors.gradAccent,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            value: '$tasksDone',
            label: S.get('tasks_label'),
            gradColors: AppColors.gradSuccess,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;
  final List<Color> gradColors;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.gradColors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (r) =>
                  LinearGradient(colors: gradColors).createShader(r),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROGRESS CARD
// ═══════════════════════════════════════════════════════════
class _ProgressCard extends StatelessWidget {
  final int done, total;
  final double progress;

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final allDone = done == total && total > 0;

    return Container(
      margin: const EdgeInsets.all(D.sp16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allDone
              ? AppColors.success.withOpacity(0.4)
              : AppColors.border,
          width: allDone ? 1.5 : 1,
        ),
        boxShadow: allDone
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    allDone
                        ? Icons.celebration_rounded
                        : Icons.flag_rounded,
                    color: allDone ? AppColors.success : AppColors.primary,
                    size: D.iconMd,
                  ),
                  const SizedBox(width: D.sp8),
                  Text(S.get('today_goal'),
                      style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: D.sp4),
                decoration: BoxDecoration(
                  color: allDone
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done / $total',
                  style: GoogleFonts.poppins(
                    color: allDone ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          allDone ? AppColors.gradSuccess : AppColors.gradPrimary,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: (allDone ? AppColors.success : AppColors.primary)
                            .withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            allDone
                ? S.get('all_done')
                : '$pct% ${S.get('completed')}',
            style: GoogleFonts.poppins(
              color: allDone ? AppColors.success : AppColors.sub,
              fontSize: 12,
              fontWeight: allDone ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: D.sp16, vertical: D.sp8),
      padding: const EdgeInsets.symmetric(vertical: D.sp48, horizontal: D.sp24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.sp20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('\u{1F680}', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: D.sp16),
          Text(S.get('no_tasks'),
              style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: D.sp8),
          Text(
            S.get('pull_refresh'),
            style: GoogleFonts.poppins(color: AppColors.sub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: D.sp20),
          Text(S.get('motto'),
              style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
