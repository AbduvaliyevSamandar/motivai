import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/task_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
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
  Timer? _notifTicker;

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

  @override
  void dispose() {
    _notifTicker?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (_inited) return;
    _inited = true;
    await Future.wait([
      context.read<TaskProvider>().loadAll(),
      context.read<ChatProvider>().init(),
    ]);
    if (!mounted) return;
    // Initial notification sync
    await context
        .read<TaskProvider>()
        .syncNotifications(context.read<NotificationProvider>());
    // Every minute check for upcoming/overdue
    _notifTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      context
          .read<TaskProvider>()
          .syncNotifications(context.read<NotificationProvider>());
    });
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
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final pop = await _onWillPop();
        if (pop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _idx, children: _screens),
        bottomNavigationBar: _FloatingGlassNav(
          index: _idx,
          onChanged: (i) {
            if (_idx == i) return;
            HapticFeedback.selectionClick();
            setState(() => _idx = i);
          },
        ),
      ),
    );
  }
}

// Bottom nav. Uses Lucide line icons; iOS-style label below the icon.
class _FloatingGlassNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _FloatingGlassNav({required this.index, required this.onChanged});

  static const _items = [
    (LucideIcons.home, 'home'),
    (LucideIcons.sparkles, 'chat'),
    (LucideIcons.trophy, 'rating'),
    (LucideIcons.lineChart, 'analytics'),
    (LucideIcons.user, 'profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = index == i;
              final (icon, label) = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: active ? AppColors.txt : AppColors.sub,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.get(label),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color:
                              active ? AppColors.txt : AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
