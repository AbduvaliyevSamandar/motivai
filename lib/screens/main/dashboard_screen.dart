import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../widgets/task_card.dart';
import '../widgets/completion_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final h     = DateTime.now().hour;
    final greet = h < 12
        ? '☀️ Xayrli tong'
        : h < 18 ? '🌤 Xayrli kun' : '🌙 Xayrli kech';

    return Scaffold(
      backgroundColor: C.bg,
      body: RefreshIndicator(
        color: C.primary,
        onRefresh: () async {
          await tasks.loadAll();
          await auth.refresh();
        },
        child: CustomScrollView(slivers: [
          // ── Header ──────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: C.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                greet:  greet,
                name:   auth.name,
                level:  auth.level,
                points: auth.points,
                streak: auth.streak,
                emoji:  auth.levelEmoji,
                daily:  tasks.completedToday,
                total:  tasks.totalToday,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout,
                    color: C.sub),
                onPressed: () =>
                    _confirmLogout(context, auth),
              ),
            ],
          ),

          // ── Loading ──────────────────────────────
          if (tasks.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Center(
                    child: CircularProgressIndicator(
                        color: C.primary)),
              ),
            )
          else ...[
            // Daily progress bar
            SliverToBoxAdapter(
              child: _ProgressCard(
                done:     tasks.completedToday,
                total:    tasks.totalToday,
                progress: tasks.dailyProgress,
              ),
            ),

            // Section header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  const Text('📋 Bugungi vazifalar',
                      style: TextStyle(
                          color: C.txt,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${tasks.completedToday}/'
                    '${tasks.totalToday}',
                    style: const TextStyle(
                        color: C.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Daily tasks
            if (tasks.daily.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(children: [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('Bugungi vazifalar yo\'q',
                        style: TextStyle(color: C.sub)),
                    SizedBox(height: 6),
                    Text('Yangilash uchun pastga torting',
                        style: TextStyle(
                            color: C.sub, fontSize: 12)),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TaskCard(
                      task: tasks.daily[i],
                      onComplete: () => _complete(
                          context, tasks,
                          tasks.daily[i]),
                    ),
                    childCount: tasks.daily.length,
                  ),
                ),
              ),

            // Recommended section
            if (tasks.recommended.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    16, 20, 16, 8),
                sliver: const SliverToBoxAdapter(
                  child: Text('🤖 AI Tavsiyalar',
                      style: TextStyle(
                          color: C.txt,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TaskCard(
                      task: tasks.recommended[i],
                      onComplete: () => _complete(
                          context, tasks,
                          tasks.recommended[i]),
                    ),
                    childCount:
                        tasks.recommended.length,
                  ),
                ),
              ),
            ],
          ],

          const SliverToBoxAdapter(
              child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Future<void> _complete(
      BuildContext ctx,
      TaskProvider tasks,
      Task task) async {
    if (task.isCompleted) return;
    final res = await tasks.complete(task.id);
    if (!ctx.mounted) return;
    if (res != null) {
      await ctx.read<AuthProvider>().refresh();
      showDialog(
        context: ctx,
        builder: (_) => CompletionDialog(
            result: res, taskTitle: task.title),
      );
    } else if (tasks.error != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(tasks.error!),
        backgroundColor: C.error));
    }
  }

  void _confirmLogout(
      BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        title: const Text('Chiqish',
            style: TextStyle(color: C.txt)),
        content: const Text('Hisobdan chiqmoqchimisiz?',
            style: TextStyle(color: C.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor',
                style: TextStyle(color: C.sub))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: C.error,
                minimumSize: const Size(80, 36)),
            child: const Text('Chiqish')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greet, name, emoji;
  final int    level, points, streak, daily, total;
  const _Header({
    required this.greet,  required this.name,
    required this.emoji,  required this.level,
    required this.points, required this.streak,
    required this.daily,  required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.surface, C.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greet,
                  style: const TextStyle(
                      color: C.sub, fontSize: 13)),
              const SizedBox(height: 4),
              Text(name,
                  style: const TextStyle(
                      color: C.txt, fontSize: 22,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: C.gradAccent),
              borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min,
                children: [
              const Text('🔥',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('$streak kun',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _Chip(emoji, 'Daraja $level'),
          const SizedBox(width: 10),
          _Chip('⭐', '$points ball'),
          const SizedBox(width: 10),
          _Chip('✅', '$daily/$total bugun'),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String e, t;
  const _Chip(this.e, this.t);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(e, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text(t,
            style: const TextStyle(
                color: C.txt, fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done, total;
  final double progress;
  const _ProgressCard(
      {required this.done,
      required this.total,
      required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
          const Text('Bugungi maqsad',
              style: TextStyle(
                  color: C.txt,
                  fontWeight: FontWeight.w600)),
          Text('$done / $total',
              style: const TextStyle(
                  color: C.primary,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: C.border,
            valueColor:
                const AlwaysStoppedAnimation(C.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done == total && total > 0
              ? '🎉 Barcha vazifalar bajarildi!'
              : '${(progress * 100).toInt()}% bajarildi',
          style:
              const TextStyle(color: C.sub, fontSize: 12),
        ),
      ]),
    );
  }
}
