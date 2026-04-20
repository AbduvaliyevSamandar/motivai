import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/progress_bar_animated.dart';
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
        backgroundColor: AppColors.card,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await tasks.loadAll();
          await auth.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _GradientHeader(
                greet: greet,
                name: auth.name,
                level: auth.level,
                streak: auth.streak,
                emoji: auth.levelEmoji,
                avatarUrl: auth.avatarUrl,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  D.sp16, D.sp8, D.sp16, D.sp4),
              sliver: SliverToBoxAdapter(
                child: _StatsGrid(
                  points: auth.points,
                  level: auth.level,
                  streak: auth.streak,
                  tasksDone: tasks.completedToday,
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(D.sp16, D.sp12, D.sp16, D.sp8),
              sliver: SliverToBoxAdapter(
                child: _ProgressCard(
                  done: tasks.completedToday,
                  total: tasks.totalToday,
                  progress: tasks.dailyProgress,
                ),
              ),
            ),
            if (tasks.isLoading && tasks.daily.isEmpty)
              const SliverToBoxAdapter(child: _LoadingBlock())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    D.sp20, D.sp16, D.sp20, D.sp8),
                sliver: SliverToBoxAdapter(
                  child: _TasksSectionHeader(
                    done: tasks.completedToday,
                    total: tasks.totalToday,
                  ),
                ),
              ),
              if (tasks.daily.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: D.sp16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _StaggeredItem(
                        index: i,
                        child: TaskCard(
                          task: tasks.daily[i],
                          onComplete: () =>
                              _complete(context, tasks, tasks.daily[i]),
                        ),
                      ),
                      childCount: tasks.daily.length,
                    ),
                  ),
                ),
              if (tasks.recommended.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      D.sp20, D.sp24, D.sp20, D.sp8),
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
                      (_, i) => _StaggeredItem(
                        index: i,
                        child: TaskCard(
                          task: tasks.recommended[i],
                          onComplete: () => _complete(
                              context, tasks, tasks.recommended[i]),
                        ),
                      ),
                      childCount: tasks.recommended.length,
                    ),
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          showAddTaskDialog(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          S.get('add_task'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _complete(
      BuildContext ctx, TaskProvider tasks, Task task) async {
    if (task.isCompleted) return;
    HapticFeedback.mediumImpact();
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
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  GRADIENT HEADER
// ═══════════════════════════════════════════════════════════
class _GradientHeader extends StatelessWidget {
  final String greet, name, emoji;
  final String? avatarUrl;
  final int level, streak;

  const _GradientHeader({
    required this.greet,
    required this.name,
    required this.emoji,
    required this.level,
    required this.streak,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  D.sp20, D.sp16, D.sp20, D.sp24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(name: name, avatarUrl: avatarUrl),
                  const SizedBox(width: D.sp12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greet,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.isNotEmpty ? name : 'User',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '${S.get('level')} $level',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: D.sp8),
                  _PulseStreak(streak: streak),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _Avatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? 'U'
        : name.trim().split(RegExp(r'\s+')).take(2).map((s) => s[0]).join();
    final hasNetwork =
        avatarUrl != null && (avatarUrl!.startsWith('http'));
    final isFile = avatarUrl != null && !hasNetwork && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Container(
          width: 52,
          height: 52,
          color: Colors.white.withOpacity(0.2),
          child: hasNetwork
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _initialsAvatar(initials),
                )
              : isFile
                  ? Image.file(
                      File(avatarUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initialsAvatar(initials),
                    )
                  : _initialsAvatar(initials),
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PulseStreak extends StatefulWidget {
  final int streak;
  const _PulseStreak({required this.streak});

  @override
  State<_PulseStreak> createState() => _PulseStreakState();
}

class _PulseStreakState extends State<_PulseStreak>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      builder: (_, __) {
        final s = 1.0 + (_ctrl.value * 0.06);
        return Transform.scale(
          scale: s,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.12 * _ctrl.value),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F525}', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(
                  '${widget.streak}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  S.get('day'),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATS GRID 2x2
// ═══════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final int points, level, streak, tasksDone;
  const _StatsGrid({
    required this.points,
    required this.level,
    required this.streak,
    required this.tasksDone,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: D.sp12,
      crossAxisSpacing: D.sp12,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          icon: Icons.star_rounded,
          value: '$points',
          label: S.get('points'),
          gradient: AppColors.gradGold,
          trend: '+12%',
        ),
        StatCard(
          icon: Icons.trending_up_rounded,
          value: '$level',
          label: S.get('level'),
          gradient: AppColors.gradPrimary,
        ),
        StatCard(
          icon: Icons.local_fire_department_rounded,
          value: '$streak',
          label: S.get('streak'),
          gradient: AppColors.gradAccent,
        ),
        StatCard(
          icon: Icons.check_circle_rounded,
          value: '$tasksDone',
          label: S.get('tasks_label'),
          gradient: AppColors.gradSuccess,
          trend: '+${tasksDone * 5}',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROGRESS CARD with ProgressBarAnimated
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
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(
          color: allDone
              ? AppColors.success.withOpacity(0.4)
              : AppColors.border.withOpacity(0.6),
          width: allDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (allDone ? AppColors.success : AppColors.primary)
                .withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: allDone
                        ? AppColors.gradSuccess
                        : AppColors.gradPrimary,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  allDone ? Icons.rocket_launch_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: D.iconMd,
                ),
              ),
              const SizedBox(width: D.sp12),
              Expanded(
                child: Text(
                  S.get('today_goal'),
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allDone
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done / $total',
                  style: GoogleFonts.poppins(
                    color: allDone
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: D.sp16),
          ProgressBarAnimated(
            value: progress,
            height: 10,
            gradient: allDone ? AppColors.gradSuccess : AppColors.gradPrimary,
          ),
          const SizedBox(height: D.sp12),
          Text(
            allDone
                ? '\u{1F389} ${S.get('all_done')}'
                : '$pct% ${S.get('completed')}',
            style: GoogleFonts.poppins(
              color: allDone ? AppColors.success : AppColors.sub,
              fontSize: 12,
              fontWeight: allDone ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════
class _TasksSectionHeader extends StatelessWidget {
  final int done, total;
  const _TasksSectionHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final allDone = done == total && total > 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(D.sp8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradPrimary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.today_rounded,
              color: Colors.white, size: D.iconMd),
        ),
        const SizedBox(width: 10),
        Text(
          S.get('today_tasks'),
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: allDone
                  ? AppColors.gradSuccess
                  : AppColors.gradPrimary,
            ),
            borderRadius: BorderRadius.circular(D.radiusMd),
          ),
          child: Text(
            '$done/$total',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STAGGERED ITEM ANIMATION
// ═══════════════════════════════════════════════════════════
class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index.clamp(0, 8)),
        () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LOADING & EMPTY
// ═══════════════════════════════════════════════════════════
class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: D.sp16),
            Text(
              S.get('loading'),
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: D.sp16, vertical: D.sp8),
      padding:
          const EdgeInsets.symmetric(vertical: D.sp48, horizontal: D.sp24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -8 * _ctrl.value),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2 * _ctrl.value),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('\u{1F680}', style: TextStyle(fontSize: 42)),
                ),
              ),
            ),
          ),
          const SizedBox(height: D.sp16),
          Text(
            S.get('no_tasks'),
            style: GoogleFonts.poppins(
              color: AppColors.txt,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: D.sp8),
          Text(
            S.get('pull_refresh'),
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: D.sp16),
          Text(
            S.get('motto'),
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
