// lib/screens/plan/plan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/plan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/plan_model.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planId;
  const PlanDetailScreen({super.key, required this.planId});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlan(widget.planId);
    });
  }

  Future<void> _completeTask(PlanModel plan, TaskModel task) async {
    final plans = context.read<PlanProvider>();
    final auth = context.read<AuthProvider>();
    
    final result = await plans.completeTask(plan.id, task.id);
    if (result != null && mounted) {
      // Update user XP in auth provider
      auth.updateUserXP(
        result['new_xp'] ?? auth.user!.xp,
        result['new_level'] ?? auth.user!.level,
        result['new_streak'] ?? auth.user!.streak,
      );

      // Show XP gained snackbar
      final xpEarned = result['xp_earned'] ?? 0;
      final newBadges = result['new_badges'] as List? ?? [];
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          content: Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('+$xpEarned XP qo\'shildi!',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              if (newBadges.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('${newBadges.first['icon']} Yangi badge!',
                    style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      if (result['plan_completed'] == true) {
        _showPlanCompletedDialog();
      }
    }
  }

  void _showPlanCompletedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('Tabriklaymiz!', style: AppTheme.heading2),
            const SizedBox(height: 8),
            const Text(
              'Siz bu rejani muvaffaqiyatli yakunladingiz!\n+100 XP qo\'shildi!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Davom etish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlanProvider>();
    final plan = plans.selectedPlan;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(plan.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppConstants.categoryIcons[plan.category] ?? '📋',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            Text(plan.goal,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${plan.progress.toInt()}% yakunlandi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text(
                        '${plan.tasksCompleted}/${plan.tasksTotal}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: plan.progress / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  if (plan.aiGenerated) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text('AI tomonidan yaratilgan',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // AI Suggestions
            if (plan.aiSuggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 AI Maslahatlar', style: AppTheme.heading3),
                    const SizedBox(height: 10),
                    ...plan.aiSuggestions.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Text('→ ',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w700)),
                              Expanded(
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            // Milestones
            if (plan.milestones.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏁 Milestonelar', style: AppTheme.heading3),
                    const SizedBox(height: 10),
                    ...plan.milestones.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: m.isCompleted
                                ? Colors.green.shade50
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: m.isCompleted
                                    ? Colors.green.shade200
                                    : AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              Text(m.isCompleted ? '✅' : '⭕',
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(m.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: m.isCompleted
                                              ? Colors.green
                                              : AppTheme.textPrimary))),
                              Text('+${m.xpReward} XP',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            // Tasks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Vazifalar (${plan.tasksCompleted}/${plan.tasksTotal})',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 10),
                  ...plan.tasks.map((task) => _TaskCard(
                        task: task,
                        onComplete: task.isCompleted
                            ? null
                            : () => _completeTask(plan, task),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onComplete;

  const _TaskCard({required this.task, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final icon = AppConstants.taskIcons[task.category] ?? '📌';
    final diffColor = task.difficulty == 'easy'
        ? Colors.green
        : task.difficulty == 'medium'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green.shade50 : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCompleted ? Colors.green.shade200 : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? Colors.green
                    : AppTheme.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? Colors.green : AppTheme.divider,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                  ),
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 2),
                  Text(task.description!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 2),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${task.durationMinutes} daq',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: diffColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(task.difficulty,
                          style: TextStyle(
                              fontSize: 10,
                              color: diffColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('⚡${task.xpReward}',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              if (!task.isCompleted && onComplete != null)
                TextButton(
                  onPressed: onComplete,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Bajardim',
                      style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
