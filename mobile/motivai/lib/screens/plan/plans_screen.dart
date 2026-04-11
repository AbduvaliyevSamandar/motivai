// lib/screens/plan/plans_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import 'plan_detail_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlanProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mening Rejalarim'),
      ),
      body: plans.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.plans.isEmpty
              ? _EmptyPlans()
              : RefreshIndicator(
                  onRefresh: () => plans.loadPlans(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plans.plans.length,
                    itemBuilder: (ctx, i) {
                      final plan = plans.plans[i];
                      return _PlanListCard(
                        plan: plan,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanDetailScreen(planId: plan.id),
                          ),
                        ).then((_) => plans.loadPlans()),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Rejani o'chirish"),
                              content: const Text("Bu rejani o'chirmoqchimisiz?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Bekor qilish"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("O'chirish",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await plans.deletePlan(plan.id);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _PlanListCard extends StatelessWidget {
  final PlanModel plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlanListCard({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppConstants.categoryIcons[plan.category] ?? '📋';
    final completed = plan.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: completed
                ? Colors.green.shade200
                : plan.isActive
                    ? AppTheme.divider
                    : AppTheme.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(plan.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (plan.aiGenerated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('🤖 AI',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(plan.goal,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: plan.progress / 100,
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation(
                        completed ? Colors.green : AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${plan.progress.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: completed ? Colors.green : AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                    icon: '📝',
                    label: '${plan.tasksCompleted}/${plan.tasksTotal} vazifa'),
                const SizedBox(width: 8),
                _Chip(icon: '📅', label: '${plan.durationDays} kun'),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.shade50
                        : plan.isActive
                            ? AppTheme.primary.withOpacity(0.08)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    completed
                        ? '✅ Yakunlangan'
                        : plan.isActive
                            ? '🔄 Faol'
                            : '⏸ Nofaol',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? Colors.green
                          : plan.isActive
                              ? AppTheme.primary
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text("Hali rejalar yo'q",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            "AI Chat orqali maqsadingizni ayting\nva AI sizga reja tuzib beradi!",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
