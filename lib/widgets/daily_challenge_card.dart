import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../config/strings.dart';
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (_completed ? AppColors.success : AppColors.accent)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
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
                      S.tr('KUNLIK CHALLENGE', 'ВЫЗОВ ДНЯ', 'DAILY CHALLENGE'),
                      style: TextStyle(
                        color: AppColors.sub,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${c.bonusXP} XP',
                        style: TextStyle(
                          color: const Color(0xFF0F1028),
                          fontSize: 10,
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
                  style: TextStyle(
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
                        borderRadius: BorderRadius.circular(8),
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
                      style: TextStyle(
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
