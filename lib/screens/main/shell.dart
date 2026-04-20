import 'dart:ui';
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

// ═══════════════════════════════════════════════════════════
//  FLOATING GLASS NAV (pill with gradient indicator)
// ═══════════════════════════════════════════════════════════
class _FloatingGlassNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _FloatingGlassNav({required this.index, required this.onChanged});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'home'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'chat'),
    (Icons.leaderboard_outlined, Icons.leaderboard_rounded, 'rating'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'analytics'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.4),
                AppColors.secondary.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.6),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24.6),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(_items.length, (i) {
                    final active = index == i;
                    final (icon, activeIcon, label) = _items[i];
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: active ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    colors: AppColors.gradCosmic,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withOpacity(0.45),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: active ? 1.05 : 1.0,
                                duration:
                                    const Duration(milliseconds: 200),
                                child: Icon(
                                  active ? activeIcon : icon,
                                  color: active
                                      ? Colors.white
                                      : AppColors.sub,
                                  size: 22,
                                ),
                              ),
                              if (active) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    S.get(label),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
