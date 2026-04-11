// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../services/api_service.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _dailyTip;
  String? _motivation;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    try {
      final api = ApiService();
      final tipRes = await api.getDailyTip();
      final motRes = await api.getQuickMotivation();
      if (mounted) {
        setState(() {
          _dailyTip = tipRes['data']['tip'];
          _motivation = motRes['data']['message'];
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final plans = context.watch<PlanProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox();

    final levelName = user.level < AppConstants.levelNames.length
        ? AppConstants.levelNames[user.level]
        : 'Champion';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salom, ${user.name}! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$levelName • ${user.level}-daraja',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.streak}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // XP Progress
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${user.xp} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${((user.level) * 100)} XP ga qadar',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (user.xp % 100) / 100,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                Row(
                  children: [
                    _statCard('📋', '${plans.stats['total_tasks_completed'] ?? user.totalTasksCompleted}',
                        'Vazifalar'),
                    const SizedBox(width: 12),
                    _statCard('⏱️', '${user.totalStudyMinutes}', "Daqiqa"),
                    const SizedBox(width: 12),
                    _statCard('📚', '${plans.stats['active_plans'] ?? 0}', 'Faol reja'),
                  ],
                ),
                const SizedBox(height: 24),

                // AI Chat CTA
                GestureDetector(
                  onTap: () {
                    // Navigate to chat tab (index 2)
                    DefaultTabController.of(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.aiGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🤖 AI Yordamchi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _motivation ?? 'Bugun ham muvaffaqiyat sari bir qadam tashlang!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Active Plans
                const Text('Faol rejalar', style: AppTheme.heading3),
                const SizedBox(height: 12),

                if (plans.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (plans.activePlans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('📭', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 12),
                        Text('Hali reja yo\'q',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        SizedBox(height: 6),
                        Text(
                          "AI bilan suhbatlashib o'zingizga reja tuzing!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...plans.activePlans.take(3).map((plan) => _PlanCard(plan: plan)),

                const SizedBox(height: 24),

                // Daily Tip
                if (_dailyTip != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kunlik maslahat',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(_dailyTip!,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary,
            )),
            Text(label, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final progress = plan.progress / 100;
    final icon = AppConstants.categoryIcons[plan.category] ?? '📋';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${plan.tasksCompleted}/${plan.tasksTotal} vazifa',
                        style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12,
                        )),
                  ],
                ),
              ),
              if (plan.aiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🤖 AI',
                      style: TextStyle(fontSize: 11, color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${plan.progress.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
