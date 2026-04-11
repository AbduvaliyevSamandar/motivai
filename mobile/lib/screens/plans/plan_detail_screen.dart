import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getPlan(widget.planId);
      setState(() {
        _plan = res['data']['plan'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _completeTask(Map<String, dynamic> task) async {
    if (task['is_completed'] == true) return;

    final result = await ref.read(plansProvider.notifier).completeTask(
      planId: widget.planId,
      taskId: task['id'],
      studyMinutes: task['duration'] ?? 0,
    );

    if (result != null && mounted) {
      // Show XP gained
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '+${result['xp_earned']} XP qozonildi!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Check level up
      if (result['level_up'] == true) {
        _showLevelUpDialog(result['level']);
      }

      await _loadPlan(); // Refresh
    }
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎊', style: TextStyle(fontSize: 72)),
              const Text('Daraja oshdi!',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Siz $level-darajaga yetdingiz!',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rahmat! 💪'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reja')),
        body: const Center(child: Text('Reja topilmadi')),
      );
    }

    final progress = (_plan!['progress'] as num?)?.toDouble() ?? 0.0;
    final tasks = (_plan!['tasks'] as List?) ?? [];
    final milestones = (_plan!['milestones'] as List?) ?? [];
    final aiSuggestions = (_plan!['ai_suggestions'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan!['title'] ?? 'Reja'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Vazifalar'),
            Tab(text: 'Milestones'),
            Tab(text: 'AI Maslahat'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceCard,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _plan!['goal'] ?? '',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tasks.where((t) => t['is_completed'] == true).length}/${tasks.length} vazifa',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 100 ? AppTheme.secondary : AppTheme.primary),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tasks tab
                tasks.isEmpty
                    ? const Center(
                        child: Text('Vazifalar yo\'q',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _TaskCard(
                          task: tasks[i],
                          onComplete: () => _completeTask(tasks[i]),
                        ),
                      ),

                // Milestones tab
                milestones.isEmpty
                    ? const Center(
                        child: Text('Milestone\'lar yo\'q',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: milestones.length,
                        itemBuilder: (_, i) =>
                            _MilestoneCard(milestone: milestones[i]),
                      ),

                // AI Suggestions tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      '🤖 AI Maslahatlari',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...aiSuggestions.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: AppTheme.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.toString(),
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
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

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onComplete;

  const _TaskCard({required this.task, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task['is_completed'] == true;
    final difficulty = task['difficulty'] ?? 'medium';
    final difficultyColors = {
      'easy': AppTheme.secondary,
      'medium': const Color(0xFFFF9800),
      'hard': const Color(0xFFFF6B6B),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.secondary.withOpacity(0.08)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.secondary.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: isCompleted ? null : onComplete,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.secondary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? AppTheme.secondary : AppTheme.divider,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        title: Text(
          task['title'] ?? '',
          style: TextStyle(
            color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.timer_outlined, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text('${task['duration'] ?? 30} daq',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (difficultyColors[difficulty] ?? AppTheme.primary)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  color: difficultyColors[difficulty] ?? AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: !isCompleted
            ? ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+${10}XP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              )
            : Text(
                '+${task['xp_reward'] ?? 10}XP',
                style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final Map<String, dynamic> milestone;

  const _MilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final isCompleted = milestone['is_completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.gold.withOpacity(0.08)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.gold.withOpacity(0.4)
              : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Text(
            isCompleted ? '🏆' : '🎯',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['title'] ?? '',
                  style: TextStyle(
                    color: isCompleted ? AppTheme.gold : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (milestone['description'] != null)
                  Text(
                    milestone['description'],
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '+${milestone['xp_reward'] ?? 50}XP',
            style: TextStyle(
              color: isCompleted ? AppTheme.gold : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
