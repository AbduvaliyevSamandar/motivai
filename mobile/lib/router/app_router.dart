import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/plans/plan_detail_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/common/main_shell.dart';
import '../services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final userState = ref.watch(userProvider);

  return GoRouter(
    initialLocation: _getInitialRoute(),
    redirect: (context, state) {
      final user = userState;

      final isAuthRoute =
          state.matchedLocation.startsWith('/auth') ||
              state.matchedLocation == '/onboarding';

      if (user == null && !isAuthRoute) {
        return '/auth/login';
      }

      if (user != null && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Main App Shell with Bottom Nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const ChatScreen(),
          ),
          GoRoute(
            path: '/plans',
            builder: (_, __) => const PlansScreen(),
            routes: [
              GoRoute(
                path: ':planId',
                builder: (_, state) => PlanDetailScreen(
                  planId: state.pathParameters['planId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Sahifa topilmadi: ${state.uri}'),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Bosh sahifaga qaytish'),
            ),
          ],
        ),
      ),
    ),
  );
});

String _getInitialRoute() {
  if (!StorageService.isOnboardingDone()) return '/onboarding';
  if (!StorageService.isLoggedIn()) return '/auth/login';
  return '/home';
}
