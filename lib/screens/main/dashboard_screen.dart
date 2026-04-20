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
import '../widgets/task_card.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/add_task_dialog.dart';
import 'notifications_screen.dart';

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
                  parent: BouncingScrollPhysics()),
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
                        D.sp20, D.sp16, D.sp20, D.sp16),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: D.sp16),
                    child: _BentoGrid(
                      points: auth.points,
                      level: auth.level,
                      streak: auth.streak,
                      tasksDone: tasks.completedToday,
                    ),
                  ),
                ),
                if (tasks.isLoading && tasks.daily.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingBlock())
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        D.sp20, D.sp24, D.sp20, D.sp12),
                    sliver: SliverToBoxAdapter(
                      child: _SectionBanner(
                        icon: Icons.rocket_launch_rounded,
                        title: S.get('today_tasks'),
                        badge: '${tasks.completedToday}/${tasks.totalToday}',
                        gradient: AppColors.gradCosmic,
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
                              onComplete: () => _complete(
                                  context, tasks, tasks.daily[i]),
                            ),
                          ),
                          childCount: tasks.daily.length,
                        ),
                      ),
                    ),
                  if (tasks.recommended.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          D.sp20, D.sp24, D.sp20, D.sp12),
                      sliver: SliverToBoxAdapter(
                        child: _SectionBanner(
                          icon: Icons.auto_awesome_rounded,
                          title: S.get('ai_suggest'),
                          gradient: AppColors.gradAurora,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: D.sp16),
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
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
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
            showAddTaskDialog(context);
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
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
        gradient: const LinearGradient(
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
//  BENTO GRID — asymmetric premium card layout
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
                  const Icon(Icons.trending_up_rounded,
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
            const CircularProgressIndicator(color: AppColors.primary),
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
                  child: const Center(
                    child:
                        Text('\u{1F680}', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.get('no_tasks'),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.get('pull_refresh'),
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
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
        ),
      ),
    );
  }
}
