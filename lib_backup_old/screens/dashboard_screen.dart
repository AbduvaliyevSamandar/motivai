import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_provider.dart';
import '../provider/data_provider.dart';
import '../provider/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    await aiProvider.fetchMotivationPlan();
    await aiProvider.fetchDailyInsight();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('MotivAI'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.brightness_4),
                  onPressed: () {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Welcome
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Text(
                        'Welcome, ${authProvider.user?.fullName?.split(' ').first ?? 'Student'}! 👋',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to achieve your goals?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatsCard(
                            title: 'Points',
                            value: '${authProvider.user?.points ?? 0}',
                            icon: Icons.star,
                          ),
                          StatsCard(
                            title: 'Level',
                            value: '${authProvider.user?.level ?? 1}',
                            icon: Icons.trending_up,
                          ),
                          StatsCard(
                            title: 'Streak',
                            value: '${authProvider.user?.streak ?? 0}',
                            icon: Icons.local_fire_department,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Daily Motivation Plan
                  Text(
                    'Today\'s Motivation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Consumer<AIProvider>(
                    builder: (context, aiProvider, _) {
                      if (aiProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (aiProvider.motivationPlan != null) {
                        final plan = aiProvider.motivationPlan!;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.taskTitle,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                plan.reason,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(plan.difficulty),
                                    side: const BorderSide(color: Colors.white),
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    '⭐ ${plan.pointsAvailable} pts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: 'Start Task',
                                onPressed: () => context.go('/tasks'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text('No tasks available'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Daily Insight
                  Text(
                    'Daily Insight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Consumer<AIProvider>(
                    builder: (context, aiProvider, _) {
                      final insight = aiProvider.dailyInsight;
                      if (insight != null) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight['motivation_message'] ?? 'Keep going!',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${insight['completed_tasks']} tasks completed'),
                                  Text('${insight['points_earned']} points earned'),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'All Tasks',
                              onPressed: () => context.go('/tasks'),
                              isSecondary: true,
                              icon: Icons.task,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Leaderboard',
                              onPressed: () => context.go('/leaderboard'),
                              isSecondary: true,
                              icon: Icons.leaderboard,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Profile',
                              onPressed: () => context.go('/profile'),
                              isSecondary: true,
                              icon: Icons.person,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Logout',
                              onPressed: () {
                                Provider.of<AuthProvider>(context, listen: false).logout();
                                context.go('/login');
                              },
                              isSecondary: true,
                              icon: Icons.logout,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
