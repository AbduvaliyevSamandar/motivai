import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';
import '../widgets/task_card.dart';
import '../widgets/completion_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _State();
}

class _State extends State<DashboardScreen> {
  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks= context.watch<TaskProvider>();
    final hour = DateTime.now().hour;
    final greet= hour < 12 ? '☀️ Xayrli tong' : hour < 18 ? '🌤 Xayrli kun' : '🌙 Xayrli kech';

    return Scaffold(
      backgroundColor: C.bg,
      body: RefreshIndicator(
        color: C.primary,
        onRefresh: () async {
          await tasks.loadAll();
          await auth.refresh();
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: C.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: _Header(
                    greet: greet, name: auth.name,
                    level: auth.level, points: auth.points,
                    streak: auth.streak, emoji: auth.levelEmoji),
              ),
              actions: [
                // Logout
                IconButton(
                  icon: const Icon(Icons.logout, color: C.sub),
                  onPressed: () => _confirmLogout(context, auth),
                ),
              ],
            ),

            // ── Daily Progress ────────────────────────
            SliverToBoxAdapter(
              child: tasks.isLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: C.primary)))
                  : _DailyProgress(
                      done: tasks.completedToday,
                      total: tasks.totalToday,
                      progress: tasks.dailyProgress),
            ),

            // ── Daily Tasks ───────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Text('📋 Bugungi vazifalar',
                        style: TextStyle(color: C.txt, fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${tasks.completedToday}/${tasks.totalToday}',
                        style: const TextStyle(color: C.primary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (tasks.daily.isEmpty && !tasks.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(children: const [
                      Text('📭', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Bugungi vazifalar yuklanmadi',
                          style: TextStyle(color: C.sub)),
                    ]),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TaskCard(
                      task: tasks.daily[i],
                      onComplete: () => _complete(context, tasks, tasks.daily[i]),
                    ),
                    childCount: tasks.daily.length,
                  ),
                ),
              ),

            // ── Recommended ───────────────────────────
            if (tasks.recommended.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: const Text('🤖 AI Tavsiya',
                      style: TextStyle(color: C.txt, fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TaskCard(
                      task: tasks.recommended[i],
                      onComplete: () => _complete(context, tasks, tasks.recommended[i]),
                    ),
                    childCount: tasks.recommended.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext ctx, TaskProvider tasks, Task task) async {
    if (task.isCompleted) return;
    final res = await tasks.complete(task.id);
    if (res != null && ctx.mounted) {
      await ctx.read<AuthProvider>().refresh();
      showDialog(
        context: ctx,
        builder: (_) => CompletionDialog(result: res, taskTitle: task.title),
      );
    } else if (tasks.error != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(tasks.error!), backgroundColor: C.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmLogout(BuildContext ctx, AuthProvider auth) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: C.card,
      title: const Text('Chiqish', style: TextStyle(color: C.txt)),
      content: const Text('Hisobdan chiqmoqchimisiz?',
          style: TextStyle(color: C.sub)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Bekor', style: TextStyle(color: C.sub))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            auth.logout(); // → main.dart Consumer LoginScreen ko'rsatadi
          },
          style: ElevatedButton.styleFrom(backgroundColor: C.error,
              minimumSize: const Size(80, 36)),
          child: const Text('Chiqish')),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String greet, name, emoji;
  final int level, points, streak;
  const _Header({required this.greet, required this.name,
      required this.level, required this.points, required this.streak,
      required this.emoji});

  @override Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.surface, C.bg],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greet, style: const TextStyle(color: C.sub, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(color: C.txt, fontSize: 22,
                            fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: C.gradAccent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('$streak kun',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(children: [
            _Stat(emoji: emoji, label: 'Daraja $level', value: ''),
            const SizedBox(width: 12),
            _Stat(emoji: '⭐', label: 'Ball', value: points.toString()),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji, label, value;
  const _Stat({required this.emoji, required this.label, required this.value});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(value.isEmpty ? label : '$label: $value',
              style: const TextStyle(color: C.txt, fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DailyProgress extends StatelessWidget {
  final int done, total;
  final double progress;
  const _DailyProgress({required this.done, required this.total, required this.progress});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bugungi maqsad',
                style: TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
            Text('$done / $total',
                style: const TextStyle(color: C.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: C.border,
            valueColor: const AlwaysStoppedAnimation(C.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done == total && total > 0
              ? '🎉 Barcha vazifalar bajarildi!'
              : '${(progress * 100).toInt()}% bajarildi',
          style: const TextStyle(color: C.sub, fontSize: 12),
        ),
      ]),
    );
  }
}
