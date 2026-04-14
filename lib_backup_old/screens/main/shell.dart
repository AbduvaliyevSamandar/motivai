import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/chat_provider.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'progress_screen.dart';
import 'achievements_screen.dart';
import '../chat/chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _State();
}

class _State extends State<MainShell> {
  int  _idx   = 0;
  bool _inited= false;

  static const _screens = [
    DashboardScreen(),
    ChatScreen(),         // AI Chat — 2-chi tab
    LeaderboardScreen(),
    ProgressScreen(),
    AchievementsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_inited) return;
    _inited = true;
    await Future.wait([
      context.read<TaskProvider>().loadAll(),
      context.read<ChatProvider>().init(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border, width: 0.8)),
      ),
      child: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: C.primary,
        unselectedItemColor: C.sub,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home),
            label: 'Bosh sahifa'),
          BottomNavigationBarItem(
            icon: _aiIcon(false), activeIcon: _aiIcon(true),
            label: 'AI Chat'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard),
            label: 'Reyting'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart),
            label: 'Tahlil'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events),
            label: 'Yutuqlar'),
        ],
      ),
    );
  }

  Widget _aiIcon(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(6),
    decoration: active
        ? BoxDecoration(
            gradient: const LinearGradient(colors: C.gradPrimary),
            borderRadius: BorderRadius.circular(10))
        : null,
    child: Icon(Icons.smart_toy_outlined,
        color: active ? Colors.white : C.sub, size: 22),
  );
}
