import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _motivationMessage;

  @override
  void initState() {
    super.initState();
    _loadMotivation();
    ref.read(userProvider.notifier).refreshProfile();
  }

  Future<void> _loadMotivation() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.quickMotivate();
      if (mounted) {
        setState(() => _motivationMessage = res['data']['message']);
      }
    } catch (e) {
      // Use default
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final plans = ref.watch(plansProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(userProvider.notifier).refreshProfile();
            await ref.read(plansProvider.notifier).load();
            await _loadMotivation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        Text(
                          user?['name'] ?? 'Foydalanuvchi',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (user?['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // XP Progress Card
                _XpCard(user: user),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: '🔥',
                        value: '${user?['streak'] ?? 0}',
                        label: 'Kun streak',
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: '✅',
                        value: '${user?['total_tasks_completed'] ?? 0}',
                        label: 'Bajarilgan',
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: '🏅',
                        value: '${(user?['badges'] as List?)?.length ?? 0}',
                        label: 'Badge',
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AI Motivation Card
                if (_motivationMessage != null)
                  _MotivationCard(message: _motivationMessage!),
                if (_motivationMessage != null) const SizedBox(height: 16),

                // Quick Actions
                const Text(
                  'Tezkor harakatlar',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.chat_bubble_rounded,
                        label: 'AI bilan\ngaplash',
                        color: AppTheme.primary,
                        onTap: () => context.go('/chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_circle_rounded,
                        label: 'Yangi\nreja',
                        color: AppTheme.secondary,
                        onTap: () => context.go('/chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.emoji_events_rounded,
                        label: 'Global\nreyting',
                        color: AppTheme.gold,
                        onTap: () => context.go('/leaderboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Plans
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Faol rejalar',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/plans'),
                      child: const Text('Barchasini ko\'r',
                          style: TextStyle(color: AppTheme.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (plans.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (plans.plans.isEmpty)
                  _EmptyPlansCard()
                else
                  ...plans.plans.take(3).map((plan) => _PlanCard(
                    plan: plan,
                    onTap: () => context.go('/plans/${plan['id']}'),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Xayrli tong ☀️';
    if (hour < 18) return 'Xayrli kun 🌤️';
    return 'Xayrli kech 🌙';
  }
}

class _XpCard extends StatelessWidget {
  final Map<String, dynamic>? user;

  const _XpCard({this.user});

  @override
  Widget build(BuildContext context) {
    final xp = user?['xp'] ?? 0;
    final level = user?['level'] ?? 1;
    final xpForNext = (level * 100);
    final xpInLevel = xp % 100;
    final progress = xpInLevel / 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getLevelColor(level),
            AppTheme.getLevelColor(level).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$level-daraja',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$xpInLevel / $xpForNext XP - Keyingi darajaga',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final String message;

  const _MotivationCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.secondary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI dan motivatsiya',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.4,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = (plan['progress'] as num?)?.toDouble() ?? 0.0;
    final tasks = (plan['tasks'] as List?)?.length ?? 0;
    final completed = (plan['tasks'] as List?)
        ?.where((t) => t['is_completed'] == true)
        .length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan['title'] ?? 'Reja',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (plan['ai_generated'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🤖 AI',
                        style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed/$tasks vazifa',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 100 ? AppTheme.secondary : AppTheme.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlansCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Hali reja yo\'q',
            style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI bilan suhbatlashib birinchi motivatsiya rejangizni tuzing!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => GoRouter.of(context).go('/chat'),
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: const Text('AI bilan boshlash'),
          ),
        ],
      ),
    );
  }
}
