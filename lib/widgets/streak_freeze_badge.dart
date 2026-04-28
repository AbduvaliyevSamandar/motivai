import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../services/streak_storage.dart';

/// Small badge showing available streak freezes.
class StreakFreezeBadge extends StatefulWidget {
  const StreakFreezeBadge({super.key});

  @override
  State<StreakFreezeBadge> createState() => _StreakFreezeBadgeState();
}

class _StreakFreezeBadgeState extends State<StreakFreezeBadge> {
  int _count = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await StreakStorage.maybeGrant(); // passive grant if 7 days elapsed
    final c = await StreakStorage.freezesAvailable();
    if (mounted) setState(() => _count = c);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Freeze: streakni saqlaydi bitta-o\'tkazib yuborilgan kunda',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.secondary.withOpacity(0.22),
            AppColors.info.withOpacity(0.12),
          ]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u2744\uFE0F', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '$_count/${StreakStorage.maxFreezes}',
              style: GoogleFonts.poppins(
                color: AppColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
