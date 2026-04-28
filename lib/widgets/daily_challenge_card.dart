import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../services/daily_challenge.dart';
import 'nebula/nebula.dart';

class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  int _progress = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await DailyChallengeService.progress();
    final done = await DailyChallengeService.isCompletedToday();
    if (mounted) {
      setState(() {
        _progress = p;
        _completed = done;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DailyChallengeService.today();
    final pct = (_progress / c.target).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColors: _completed
          ? [AppColors.success, AppColors.accent]
          : [AppColors.accent, AppColors.pink],
      glowIntensity: _completed ? 0.3 : 0.2,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _completed
                    ? AppColors.gradSuccess
                    : AppColors.gradFire,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_completed
                          ? AppColors.success
                          : AppColors.accent)
                      .withOpacity(0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _completed ? '\u2705' : c.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'KUNLIK CHALLENGE',
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: AppColors.gradGold),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${c.bonusXP} XP',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F1028),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.title,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor:
                              AppColors.border.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _completed
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_progress/${c.target}',
                      style: GoogleFonts.poppins(
                        color: _completed
                            ? AppColors.success
                            : AppColors.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
