import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> _items = const [
    _NavItem(path: '/home', icon: Icons.home_rounded, label: 'Bosh'),
    _NavItem(path: '/chat', icon: Icons.chat_bubble_rounded, label: 'AI Chat'),
    _NavItem(path: '/plans', icon: Icons.checklist_rounded, label: 'Rejalar'),
    _NavItem(path: '/progress', icon: Icons.bar_chart_rounded, label: 'Progress'),
    _NavItem(path: '/leaderboard', icon: Icons.emoji_events_rounded, label: 'Reyting'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          top: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _items.map((item) {
              final isActive = location.startsWith(item.path);
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Special AI Chat button
                      if (item.path == '/chat')
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.secondary])
                                : null,
                            color: isActive ? null : AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                            size: 22,
                          ),
                        )
                      else
                        Icon(
                          item.icon,
                          color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                          size: 24,
                        ),
                      if (item.path != '/chat') ...[
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem({required this.path, required this.icon, required this.label});
}
