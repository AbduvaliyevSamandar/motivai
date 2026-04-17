import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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
    final auth  = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final h     = DateTime.now().hour;
    final greet = h < 12
        ? S.get('good_morning')
        : h < 18
            ? S.get('good_day')
            : S.get('good_evening');

    return Scaffold(
      backgroundColor: C.bg,
      floatingActionButton: _buildFAB(context),
      body: RefreshIndicator(
        color: C.primary,
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
                        CircularProgressIndicator(color: C.primary),
                        const SizedBox(height: 16),
                        Text(S.get('loading'),
                            style: TextStyle(color: C.sub, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // ── Today Tasks Section Header ─────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: C.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.today_rounded,
                          color: C.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(S.get('today_tasks'),
                        style: TextStyle(
                            color: C.txt,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tasks.dailyProgress >= 1.0
                              ? C.gradGreen
                              : C.gradPrimary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.completedToday}/${tasks.totalToday}',
                        style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: C.gradAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(S.get('ai_suggest'),
                          style: TextStyle(
                              color: C.txt,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
        gradient: const LinearGradient(colors: C.gradPrimary),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: C.primary.withOpacity(0.4),
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
            style: const TextStyle(
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
        backgroundColor: C.error,
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
            C.primary.withOpacity(0.15),
            C.accent.withOpacity(0.08),
            C.bg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + streak badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greet,
                            style: TextStyle(
                                color: C.sub,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name.isNotEmpty ? name : 'User',
                                style: TextStyle(
                                    color: C.txt,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: C.gradPrimary),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emoji,
                                      style: const TextStyle(
                                          fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${S.get('level')} $level',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Streak fire badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: C.gradAccent),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: C.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('$streak',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(S.get('day'),
                            style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            iconColor: C.gold,
            value: '$points',
            label: S.get('points'),
            gradColors: C.gradGold,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.trending_up_rounded,
            iconColor: C.primary,
            value: '$level',
            label: S.get('level'),
            gradColors: C.gradPrimary,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: C.accent,
            value: '$streak',
            label: S.get('streak'),
            gradColors: C.gradAccent,
          ),
          const SizedBox(width: 10),
          _StatItem(
            icon: Icons.check_circle_rounded,
            iconColor: C.success,
            value: '$tasksDone',
            label: S.get('tasks_label'),
            gradColors: C.gradGreen,
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
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border),
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
                style: TextStyle(
                    color: C.txt,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: C.sub, fontSize: 11)),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allDone
              ? C.success.withOpacity(0.4)
              : C.border,
          width: allDone ? 1.5 : 1,
        ),
        boxShadow: allDone
            ? [
                BoxShadow(
                  color: C.success.withOpacity(0.1),
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
                    color: allDone ? C.success : C.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(S.get('today_goal'),
                      style: TextStyle(
                          color: C.txt,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allDone
                      ? C.success.withOpacity(0.15)
                      : C.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done / $total',
                  style: TextStyle(
                    color: allDone ? C.success : C.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: C.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: allDone ? C.gradGreen : C.gradPrimary,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: (allDone ? C.success : C.primary)
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
            style: TextStyle(
              color: allDone ? C.success : C.sub,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  C.primary.withOpacity(0.15),
                  C.accent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(S.get('no_tasks'),
              style: TextStyle(
                  color: C.txt,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            S.get('pull_refresh'),
            style: TextStyle(color: C.sub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(S.get('motto'),
              style: TextStyle(
                  color: C.primary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
