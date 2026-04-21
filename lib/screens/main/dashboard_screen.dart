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
import '../../providers/notification_provider.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';
import '../../widgets/daily_quote_card.dart';
import '../../widgets/daily_challenge_card.dart';
import '../../services/daily_challenge.dart';
import '../../services/coins_storage.dart';
import '../../widgets/coins_badge.dart';
import '../widgets/task_card.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/add_task_dialog.dart';
import 'notifications_screen.dart';
import 'calendar_screen.dart';
import 'search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCompleted = false;

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
      extendBodyBehindAppBar: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: _buildFAB(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 26),
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await tasks.loadAll();
              await auth.refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          D.sp20, D.sp16, D.sp20, 8),
                      child: _HeaderRow(
                        greet: greet,
                        name: auth.name,
                        level: auth.level,
                        emoji: auth.levelEmoji,
                        avatarUrl: auth.avatarUrl,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        D.sp16, D.sp12, D.sp16, D.sp8),
                    child: _HeroXPRing(
                      points: auth.points,
                      level: auth.level,
                      completedToday: tasks.completedToday,
                      totalToday: tasks.totalToday,
                      dailyProgress: tasks.dailyProgress,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        D.sp16, 0, D.sp16, 8),
                    child: _QuickStats(
                      points: auth.points,
                      streak: auth.streak,
                      tasksDone: tasks.completedToday,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        D.sp16, 4, D.sp16, 8),
                    child: DailyChallengeCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        D.sp16, 4, D.sp16, 4),
                    child: DailyQuoteCard(),
                  ),
                ),
                if (tasks.isLoading && tasks.all.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingBlock())
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        D.sp20, D.sp24, D.sp20, D.sp12),
                    sliver: SliverToBoxAdapter(
                      child: _SectionBanner(
                        icon: Icons.rocket_launch_rounded,
                        title: 'Vazifalar',
                        badge: '${tasks.completedToday}/${tasks.totalToday}',
                        gradient: AppColors.gradCosmic,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        D.sp16, 0, D.sp16, D.sp12),
                    sliver: SliverToBoxAdapter(
                      child: _TaskToggle(
                        showCompleted: _showCompleted,
                        activeCount: tasks.active.length,
                        doneCount: tasks.completed.length,
                        onChanged: (v) => setState(() => _showCompleted = v),
                      ),
                    ),
                  ),
                  _buildTaskList(context, tasks),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, TaskProvider tasks) {
    final list = _showCompleted ? tasks.completed : tasks.active;
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(completed: _showCompleted),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: D.sp16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _StaggeredItem(
            index: i,
            child: TaskCard(
              task: list[i],
              pinned: tasks.isPinned(list[i].id),
              onComplete: () => _complete(context, tasks, list[i]),
              onEdit: () => _edit(context, list[i]),
              onDelete: () => _confirmDelete(context, tasks, list[i]),
              onPin: () => tasks.togglePin(list[i].id),
            ),
          ),
          childCount: list.length,
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext ctx, Task task) async {
    HapticFeedback.selectionClick();
    showAddTaskDialog(ctx, editTask: task);
  }

  Future<void> _confirmDelete(
      BuildContext ctx, TaskProvider tasks, Task task) async {
    HapticFeedback.mediumImpact();
    // Optimistic: delete immediately + show undo snackbar
    final done =
        await tasks.deleteTask(task.id, planId: task.planId);
    if (!ctx.mounted) return;
    if (done) {
      final messenger = ScaffoldMessenger.of(ctx);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${task.title}" o\'chirildi',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'BEKOR QILISH',
          textColor: Colors.white,
          onPressed: () async {
            HapticFeedback.lightImpact();
            // Recreate the task
            await tasks.createTask(
              title: task.title,
              description: task.description,
              category: task.category,
              difficulty: task.difficulty,
              durationMinutes: task.durationMinutes,
              xpReward: task.points,
              scheduledAt: task.scheduledAt,
              reminderMinutes: task.reminderMinutes,
            );
          },
        ),
      ));
    } else if (tasks.error != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(tasks.error!),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.pink.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Always switch to Faol when opening add — new task lives there
            if (_showCompleted) {
              setState(() => _showCompleted = false);
            }
            showAddTaskDialog(context);
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.gradCosmic,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
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
      // Daily challenge progress (completeN type)
      final ch = DailyChallengeService.today();
      if (ch.type == ChallengeType.completeN ||
          ch.type == ChallengeType.streakKeep) {
        await DailyChallengeService.increment();
      }
      // Award coins based on difficulty
      await CoinsStorage.add(CoinsStorage.taskReward(task.difficulty));
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
//  HEADER ROW — greeting + avatar + notification
// ═══════════════════════════════════════════════════════════
class _HeaderRow extends StatelessWidget {
  final String greet, name, emoji;
  final int level;
  final String? avatarUrl;

  const _HeaderRow({
    required this.greet,
    required this.name,
    required this.level,
    required this.emoji,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(name: name, avatarUrl: avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greet,
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? 'User' : name,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.txt,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Search button
        Builder(builder: (ctx) {
          return Material(
            color: AppColors.card.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  ctx,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.sub,
                  size: 20,
                ),
              ),
            ),
          );
        }),
        // Coins badge
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CoinsBadge(),
        ),
        // Calendar button
        Builder(builder: (ctx) {
          return Material(
            color: AppColors.card.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  ctx,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const CalendarScreen(),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.sub,
                  size: 20,
                ),
              ),
            ),
          );
        }),
        Consumer<NotificationProvider>(
          builder: (ctx, np, __) {
            final unread = np.unreadCount;
            return Material(
              color: AppColors.card.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    ctx,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const NotificationsScreen(),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(a),
                          child: c,
                        ),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(Icons.notifications_outlined,
                            color: unread > 0
                                ? AppColors.primary
                                : AppColors.sub,
                            size: 20),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.gradWarning),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.danger.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
        avatarUrl != null && avatarUrl!.startsWith('http');
    final isFile = avatarUrl != null && !hasNetwork && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.gradCosmic,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: 48,
          height: 48,
          color: AppColors.card,
          child: hasNetwork
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ini(initials),
                )
              : isFile
                  ? Image.file(
                      File(avatarUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ini(initials),
                    )
                  : _ini(initials),
        ),
      ),
    );
  }

  Widget _ini(String s) => Center(
        child: Text(
          s.toUpperCase(),
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  HERO XP RING CARD
// ═══════════════════════════════════════════════════════════
class _HeroXPRing extends StatelessWidget {
  final int points, level, completedToday, totalToday;
  final double dailyProgress;

  const _HeroXPRing({
    required this.points,
    required this.level,
    required this.completedToday,
    required this.totalToday,
    required this.dailyProgress,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = completedToday == totalToday && totalToday > 0;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      glowColors: allDone
          ? [AppColors.success, AppColors.accent]
          : [AppColors.primary, AppColors.secondary],
      glowIntensity: 0.4,
      child: Row(
        children: [
          XPRing(
            progress: dailyProgress,
            size: 140,
            strokeWidth: 10,
            gradientColors: allDone
                ? [
                    AppColors.success,
                    AppColors.accent,
                    AppColors.success,
                  ]
                : AppColors.gradCosmic,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completedToday',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.txt,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  '/ $totalToday',
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: D.sp20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.get('today_goal').toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: allDone
                        ? AppColors.gradSuccess
                        : AppColors.gradCosmic,
                  ).createShader(b),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    '${(dailyProgress * 100).toInt()}%',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  allDone
                      ? '${S.get("all_done")} 🎉'
                      : S.get('completed'),
                  style: GoogleFonts.poppins(
                    color: allDone
                        ? AppColors.success
                        : AppColors.sub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$points XP',
                      style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Lvl $level',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  QUICK STATS — compact horizontal chips
// ═══════════════════════════════════════════════════════════
class _QuickStats extends StatelessWidget {
  final int points, streak, tasksDone;
  const _QuickStats({
    required this.points,
    required this.streak,
    required this.tasksDone,
  });

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.star_rounded,
              value: _fmt(points),
              label: 'XP',
              gradient: AppColors.gradGold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              label: 'streak',
              gradient: AppColors.gradFire,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: Icons.check_circle_rounded,
              value: '$tasksDone',
              label: 'bajarildi',
              gradient: AppColors.gradSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gradient.first.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.txt,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BENTO GRID (legacy, not used anymore — kept for ref)
// ═══════════════════════════════════════════════════════════
class _BentoGrid extends StatelessWidget {
  final int points, level, streak, tasksDone;

  const _BentoGrid({
    required this.points,
    required this.level,
    required this.streak,
    required this.tasksDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: BentoCard(
                customChild: _StreakCustom(streak: streak),
                height: 160,
                accent: AppColors.accent,
                gradient: AppColors.gradFire,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  BentoCard(
                    icon: Icons.star_rounded,
                    value: _fmt(points),
                    label: 'XP',
                    gradient: AppColors.gradGold,
                    accent: AppColors.accent,
                    trend: '+12%',
                    height: 75,
                  ),
                  const SizedBox(height: 10),
                  BentoCard(
                    icon: Icons.check_circle_rounded,
                    value: '$tasksDone',
                    label: S.get('tasks_label'),
                    gradient: AppColors.gradSuccess,
                    accent: AppColors.success,
                    height: 75,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StreakCustom extends StatefulWidget {
  final int streak;
  const _StreakCustom({required this.streak});

  @override
  State<_StreakCustom> createState() => _StreakCustomState();
}

class _StreakCustomState extends State<_StreakCustom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + 0.08 * _ctrl.value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradFire,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent
                            .withOpacity(0.4 + 0.3 * _ctrl.value),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Text('\u{1F525}',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 11, color: AppColors.success),
                  const SizedBox(width: 2),
                  Text(
                    'best',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: AppColors.gradFire,
              ).createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                '${widget.streak}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 54,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -3,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.get('day'),
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          S.get('streak').toUpperCase(),
          style: GoogleFonts.poppins(
            color: AppColors.sub,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SECTION BANNER
// ═══════════════════════════════════════════════════════════
class _SectionBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final List<Color> gradient;

  const _SectionBanner({
    required this.icon,
    required this.title,
    this.badge,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.txt,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STAGGERED ITEM
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
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
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
//  LOADING + EMPTY
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
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
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
  final bool completed;
  const _EmptyState({this.completed = false});
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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.completed;
    final emoji = completed ? '\u{1F389}' : '\u{1F680}';
    final title = completed ? 'Hali bajarilgan vazifa yo\'q' : S.get('no_tasks');
    final sub = completed
        ? "Vazifalarni bajaring — bu yerda ko'rinadi"
        : S.get('pull_refresh');

    return Padding(
      padding: const EdgeInsets.all(D.sp16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
            vertical: D.sp48, horizontal: D.sp24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, -10 * _ctrl.value),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.25),
                        AppColors.pink.withOpacity(0.18),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.3 * _ctrl.value),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (!completed) ...[
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: AppColors.gradAurora,
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  S.get('motto'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TASK TOGGLE (Faol / Bajarilgan)
// ═══════════════════════════════════════════════════════════
class _TaskToggle extends StatelessWidget {
  final bool showCompleted;
  final int activeCount;
  final int doneCount;
  final ValueChanged<bool> onChanged;

  const _TaskToggle({
    required this.showCompleted,
    required this.activeCount,
    required this.doneCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _segment('Faol', activeCount, !showCompleted,
              () => onChanged(false)),
          _segment('Bajarilgan', doneCount, showCompleted,
              () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, int count, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: AppColors.gradCosmic)
                : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: active ? Colors.white : AppColors.sub,
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.22)
                      : AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.spaceGrotesk(
                    color: active ? Colors.white : AppColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
