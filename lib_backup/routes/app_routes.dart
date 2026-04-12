import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen_modern.dart';
import '../screens/register_screen_modern.dart';
import '../screens/main_navigation.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen_modern.dart';
import '../screens/ai_chat_screen.dart';
import '../provider/auth_provider.dart';

final appRoutes = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuthenticated = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).isAuthenticated;

    if (!isAuthenticated) {
      if (state.matchedLocation == '/register' || state.matchedLocation == '/splash') {
        return null;
      }
      return '/login';
    }

    if (state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/splash') {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigation(),
    ),
  ],
);
