import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/task_provider.dart';
import '../../providers/chat_provider.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import '../chat/chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _ShellState();
}

class _ShellState extends State<MainShell> {
  int _idx = 0;
  bool _inited = false;
  DateTime? _lastBack;

  final _screens = const [
    DashboardScreen(),
    ChatScreen(),
    LeaderboardScreen(),
    ProgressScreen(),
    ProfileScreen(),
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

  Future<bool> _onWillPop() async {
    if (_idx != 0) {
      setState(() => _idx = 0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return true;
    }

    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.get('back_exit'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusMd),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _idx, children: _screens),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.sp8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded,
                  S.get('home')),
              _navItem(1, Icons.smart_toy_outlined, Icons.smart_toy_rounded,
                  S.get('chat'),
                  isAI: true),
              _navItem(2, Icons.leaderboard_outlined,
                  Icons.leaderboard_rounded, S.get('rating')),
              _navItem(3, Icons.bar_chart_outlined, Icons.bar_chart_rounded,
                  S.get('analytics')),
              _navItem(4, Icons.person_outline_rounded,
                  Icons.person_rounded, S.get('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label,
      {bool isAI = false}) {
    final active = _idx == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _idx = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: D.sp4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAI)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(colors: AppColors.gradPrimary)
                        : null,
                    color: active ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(D.radiusMd),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? Colors.white : AppColors.hint,
                    size: 22,
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    active ? activeIcon : icon,
                    key: ValueKey(active),
                    color: active ? AppColors.primary : AppColors.hint,
                    size: D.iconLg,
                  ),
                ),
              const SizedBox(height: D.sp4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: active ? AppColors.primary : AppColors.hint,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: AppColors.gradPrimary)
                      : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
