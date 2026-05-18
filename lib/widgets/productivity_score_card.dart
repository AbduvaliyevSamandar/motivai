import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../config/colors.dart';
import '../config/strings.dart';
import '../models/models.dart';
import 'nebula/nebula.dart';

/// Computes a 0-100 productivity score from recent tasks + shows a summary.
class ProductivityScoreCard extends StatelessWidget {
  final List<Task> tasks;
  final int streak;
  const ProductivityScoreCard({
    super.key,
    required this.tasks,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final best = _bestDayOfWeek();
    final mostProductiveHour = _mostProductiveHour();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Iconsax.flash,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                S.tr('Samaradorlik', 'Продуктивность', 'Productivity'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '$score',
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2,
                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              _scoreEmoji(score),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _scoreLabel(score),
            style: TextStyle(
              color: AppColors.sub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.border.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 70
                    ? AppColors.success
                    : score >= 40
                        ? AppColors.accent
                        : AppColors.danger,
              ),
            ),
          ),
          if (best != null || mostProductiveHour != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (best != null)
                  Expanded(
                    child: _miniStat(
                      '\u{1F4C5}',
                      S.tr('Yaxshi kun', 'Лучший день', 'Best day'),
                      best,
                    ),
                  ),
                if (best != null && mostProductiveHour != null)
                  const SizedBox(width: 8),
                if (mostProductiveHour != null)
                  Expanded(
                    child: _miniStat(
                      '\u{23F0}',
                      S.tr('Yaxshi vaqt', 'Лучшее время', 'Best time'),
                      mostProductiveHour,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreEmoji(int score) {
    final emoji = score >= 85
        ? '\u{1F525}'
        : score >= 60
            ? ''
            : score >= 30
                ? '\u{1F680}'
                : '\u{1F331}';
    return Text(emoji, style: const TextStyle(fontSize: 24));
  }

  String _scoreLabel(int score) {
    if (score >= 85) return S.tr('Ajoyib! Kuchli davom eting', 'Отлично! Так держать', 'Excellent! Keep it up');
    if (score >= 60) return S.tr('Yaxshi natija', 'Хороший результат', 'Good result');
    if (score >= 30) return S.tr('Yaxshi start — yanada ko\'paytiring', 'Хороший старт — увеличьте темп', 'Good start — pick up the pace');
    return S.tr('Endigina boshladik — har qadam muhim', 'Только начали — каждый шаг важен', 'Just started — every step counts');
  }

  int _calculateScore() {
    // Score components:
    // - Completion rate (up to 40)
    // - Streak bonus (up to 30)
    // - Volume (up to 30)
    final total = tasks.length;
    if (total == 0) return 0;
    final completed = tasks.where((t) => t.isCompleted).length;

    final completionRate = total > 0 ? completed / total : 0.0;
    final completionScore = (completionRate * 40).round();

    final streakScore = streak >= 30
        ? 30
        : streak >= 14
            ? 25
            : streak >= 7
                ? 18
                : streak >= 3
                    ? 10
                    : streak >= 1
                        ? 4
                        : 0;

    final volumeScore = completed >= 50
        ? 30
        : completed >= 20
            ? 22
            : completed >= 10
                ? 15
                : completed >= 5
                    ? 8
                    : completed >= 1
                        ? 3
                        : 0;

    return (completionScore + streakScore + volumeScore).clamp(0, 100);
  }

  String? _bestDayOfWeek() {
    final counts = <int, int>{};
    for (final t in tasks) {
      final d = t.completedAt;
      if (d == null) continue;
      counts[d.weekday] = (counts[d.weekday] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final names = {
      1: S.tr('Du', 'Пн', 'Mon'),
      2: S.tr('Se', 'Вт', 'Tue'),
      3: S.tr('Ch', 'Ср', 'Wed'),
      4: S.tr('Pa', 'Чт', 'Thu'),
      5: S.tr('Ju', 'Пт', 'Fri'),
      6: S.tr('Sh', 'Сб', 'Sat'),
      7: S.tr('Ya', 'Вс', 'Sun'),
    };
    return names[best.key];
  }

  String? _mostProductiveHour() {
    final counts = <int, int>{};
    for (final t in tasks) {
      final d = t.completedAt;
      if (d == null) continue;
      counts[d.hour] = (counts[d.hour] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${best.key.toString().padLeft(2, '0')}:00';
  }
}
