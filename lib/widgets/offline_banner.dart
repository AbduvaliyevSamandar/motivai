import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import '../services/action_queue.dart';

/// Thin status strip that appears when offline OR when pending actions
/// are queued. Taps to force sync.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActionQueue>(
      builder: (_, q, __) {
        final showOffline = !q.online;
        final showPending = q.pendingCount > 0;
        if (!showOffline && !showPending) return const SizedBox.shrink();
        final danger = showOffline;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                q.syncNow();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (danger ? AppColors.danger : AppColors.accent)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (danger
                            ? AppColors.danger
                            : AppColors.accent)
                        .withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      danger
                          ? LucideIcons.cloudOff
                          : (q.syncing
                              ? LucideIcons.refreshCw
                              : LucideIcons.uploadCloud),
                      color: danger
                          ? AppColors.danger
                          : AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        danger
                            ? 'Oflayn — amallar navbatga qo\'shiladi'
                            : q.syncing
                                ? 'Sinxronlanmoqda…'
                                : '${q.pendingCount} ta amal navbatda — bosing',
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ),
                    if (!danger)
                      Icon(LucideIcons.refreshCw,
                          color: AppColors.accent, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
