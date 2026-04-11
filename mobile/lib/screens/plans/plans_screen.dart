import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motivatsiya Rejalari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(plansProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/chat'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('AI bilan yaratish'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.plans.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(plansProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.plans.length,
                    itemBuilder: (_, i) {
                      final plan = state.plans[i];
                      return _PlanListCard(
                        plan: plan,
                        onTap: () => context.go('/plans/${plan['id'] ?? plan['_id']}'),
                        onDelete: () async {
                          final confirm = await _confirmDelete(context);
                          if (confirm == true) {
                            ref.read(plansProvider.notifier)
                                .deletePlan(plan['id'] ?? plan['_id']);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Rejani o\'chirish',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu rejani o\'chirishni tasdiqlaysizmi?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('O\'chirish',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}

class _PlanListCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlanListCard({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (plan['progress'] as num?)?.toDouble() ?? 0.0;
    final category = plan['category'] ?? 'academic';
    final aiGenerated = plan['ai_generated'] == true;

    final categoryColors = {
      'academic': AppTheme.primary,
      'personal': AppTheme.secondary,
      'career': const Color(0xFFFF9800),
      'health': const Color(0xFF66BB6A),
      'skills': const Color(0xFFAB47BC),
      'language': const Color(0xFF42A5F5),
    };

    final color = categoryColors[category] ?? AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            // Color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan['title'] ?? 'Reja',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (aiGenerated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🤖 AI',
                              style: TextStyle(
                                  color: AppTheme.primary, fontSize: 10)),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            color: AppTheme.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  if (plan['goal'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan['goal'],
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(plan['tasks'] as List?)?.where((t) => t['is_completed'] == true).length ?? 0}/'
                        '${(plan['tasks'] as List?)?.length ?? 0} vazifa',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Hali rejalar yo\'q',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI bilan suhbatlashib birinchi motivatsiya rejangizni tuzing!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/chat'),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('AI bilan boshlash'),
            ),
          ],
        ),
      ),
    );
  }
}
