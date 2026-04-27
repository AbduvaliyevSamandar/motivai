import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
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
      glowColors: [AppColors.accent, AppColors.primary],
      glowIntensity: 0.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: AppColors.gradCosmic),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Samaradorlik',
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 14,
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
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                        colors: AppColors.gradCosmic)
                    .createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  '$score',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 14,
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
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
                      'Yaxshi kun',
                      best,
                    ),
                  ),
                if (best != null && mostProductiveHour != null)
                  const SizedBox(width: 8),
                if (mostProductiveHour != null)
                  Expanded(
                    child: _miniStat(
                      '\u{23F0}',
                      'Yaxshi vaqt',
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 12,
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
            ? '\u{1F4AA}'
            : score >= 30
                ? '\u{1F680}'
                : '\u{1F331}';
    return Text(emoji, style: const TextStyle(fontSize: 28));
  }

  String _scoreLabel(int score) {
    if (score >= 85) return 'Ajoyib! Kuchli davom eting';
    if (score >= 60) return 'Yaxshi natija';
    if (score >= 30) return 'Yaxshi start — yanada ko\'paytiring';
    return 'Endigina boshladik — her qadam muhim';
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
    const names = {
      1: 'Du', 2: 'Se', 3: 'Ch', 4: 'Pa', 5: 'Ju', 6: 'Sh', 7: 'Ya',
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
