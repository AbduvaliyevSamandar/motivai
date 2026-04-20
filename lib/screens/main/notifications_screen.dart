import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
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
          const AuroraBackground(subtle: true),
          const ParticleField(count: 18),
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
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.txt, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: AppColors.titleGradient,
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Bildirishnomalar',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (np.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.gradCosmic),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${np.unreadCount}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (np.feed.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: AppColors.sub),
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                      "Barchasini o'qilgan qilish",
                      style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Hammasini tozalash',
                      style: GoogleFonts.poppins(
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
        return Icons.notifications_active_rounded;
      case AppNotifType.overdue:
        return Icons.error_outline_rounded;
      case AppNotifType.achievement:
        return Icons.emoji_events_rounded;
      case AppNotifType.info:
        return Icons.info_outline_rounded;
    }
  }

  String _relTime() {
    final diff = DateTime.now().difference(notif.at);
    if (diff.inMinutes < 1) return 'hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
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
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onRemove();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: notif.read
                    ? null
                    : LinearGradient(colors: [
                        _accent.withOpacity(0.08),
                        _accent.withOpacity(0.02),
                      ]),
                color: notif.read ? AppColors.card.withOpacity(0.5) : null,
                borderRadius: BorderRadius.circular(16),
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
                      gradient: LinearGradient(colors: [
                        _accent.withOpacity(0.25),
                        _accent.withOpacity(0.08),
                      ]),
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
                                style: GoogleFonts.poppins(
                                  color: AppColors.txt,
                                  fontSize: 14,
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
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _relTime(),
                          style: GoogleFonts.poppins(
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.1),
                ]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.primary, size: 46),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: AppColors.titleGradient,
              ).createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Bildirishnomalar yo\'q',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vazifalaringizga vaqt qo\'shing —\neslatmalar shu yerda ko\'rinadi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
