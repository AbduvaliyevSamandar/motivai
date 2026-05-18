import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../models/models.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/nebula/nebula.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(),
                Expanded(
                  child: Consumer<NotificationProvider>(
                    builder: (_, np, __) {
                      if (np.feed.isEmpty) {
                        return const _EmptyFeed();
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: np.feed.length,
                        itemBuilder: (_, i) => _NotifTile(
                          notif: np.feed[i],
                          onTap: () => np.markRead(np.feed[i].id),
                          onRemove: () => np.remove(np.feed[i].id),
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft,
                color: AppColors.txt, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          Text(
              S.get('notifications'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          if (np.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${np.unreadCount}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            ),
          ],
          const Spacer(),
          if (np.feed.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical,
                  color: AppColors.sub),
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'read',
                  child: Row(children: [
                    Icon(Icons.done_all_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      S.get('mark_all_read'),
                      style: TextStyle(
                        color: AppColors.txt,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(children: [
                    Icon(LucideIcons.trash2,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      S.get('clear_all'),
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                ),
              ],
              onSelected: (v) {
                HapticFeedback.selectionClick();
                if (v == 'read') np.markAllRead();
                if (v == 'clear') np.clear();
              },
            ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotif notif;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onRemove,
  });

  Color get _accent {
    switch (notif.type) {
      case AppNotifType.reminder:
        return AppColors.accent;
      case AppNotifType.overdue:
        return AppColors.danger;
      case AppNotifType.achievement:
        return AppColors.secondary;
      case AppNotifType.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case AppNotifType.reminder:
        return LucideIcons.bell;
      case AppNotifType.overdue:
        return LucideIcons.alertCircle;
      case AppNotifType.achievement:
        return Iconsax.cup;
      case AppNotifType.info:
        return LucideIcons.info;
    }
  }

  String _relTime() {
    final diff = DateTime.now().difference(notif.at);
    if (diff.inMinutes < 1) return S.tr('hozir', 'сейчас', 'now');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${S.get("min_ago")}';
    if (diff.inHours < 24) return '${diff.inHours} ${S.get("hour_ago")}';
    if (diff.inDays < 7) return '${diff.inDays} ${S.get("day_ago")}';
    return '${notif.at.day}/${notif.at.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        child:
            Icon(LucideIcons.trash2, color: AppColors.danger),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onRemove();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: notif.read
                    ? AppColors.surface
                    : _accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: notif.read
                      ? AppColors.border
                      : _accent.withOpacity(0.35),
                  width: notif.read ? 1 : 1.3,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.4)),
                    ),
                    child: Icon(_icon, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  color: AppColors.txt,
                                  fontSize: 13,
                                  fontWeight: notif.read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notif.read) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: AppColors.sub,
                            fontSize: 11,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _relTime(),
                          style: TextStyle(
                            color: AppColors.hint,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
                S.get('notif_no'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              S.get('tasks_show_here_x'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.sub,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
