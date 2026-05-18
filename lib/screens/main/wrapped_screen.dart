import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/nebula/nebula.dart';

/// "Spotify Wrapped" style weekly summary.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});
  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  int _slide = 0;
  final _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();

    // Compute weekly stats from tasks' completedAt within last 7 days
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final weekTasks = tasks.all.where((t) {
      final c = t.completedAt;
      return c != null && c.isAfter(weekStart);
    }).toList();
    final totalCompleted = weekTasks.length;
    final totalXP =
        weekTasks.fold<int>(0, (s, t) => s + t.points);
    final categories = <String, int>{};
    for (final t in weekTasks) {
      categories[t.category] = (categories[t.category] ?? 0) + 1;
    }
    final topCategory = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = topCategory.isEmpty ? 'study' : topCategory.first.key;

    final slides = [
      _Slide(
        emoji: '\u{1F389}',
        title: S.get('wrapped_title'),
        subtitle: S.get('wrapped_subtitle'),
        highlight: '${now.subtract(const Duration(days: 6)).day} — ${now.day}',
        gradient: AppColors.gradCosmic,
      ),
      _Slide(
        emoji: '\u{2705}',
        title: S.get('wrapped_tasks_done'),
        subtitle: S.get('wrapped_tasks_sub'),
        highlight: '$totalCompleted',
        bigLabel: totalCompleted == 1 ? 'ta' : 'ta',
        gradient: AppColors.gradSuccess,
      ),
      _Slide(
        emoji: '\u{2B50}',
        title: S.get('wrapped_xp'),
        subtitle: S.get('wrapped_xp_sub'),
        highlight: '+$totalXP',
        bigLabel: 'XP',
        gradient: AppColors.gradGold,
      ),
      _Slide(
        emoji: '\u{1F525}',
        title: S.get('streak'),
        subtitle: S.get('active_streak'),
        highlight: '${auth.streak}',
        bigLabel: 'kun',
        gradient: AppColors.gradFire,
      ),
      _Slide(
        emoji: _catEmoji(topCat),
        title: S.get('wrapped_top_cat'),
        subtitle: S.get('preferred_field'),
        highlight: _catLabel(topCat),
        gradient: AppColors.gradAurora,
      ),
      _Slide(
        emoji: '\u{1F680}',
        title: S.get('wrapped_keep_going'),
        subtitle: S.get('wrapped_next_higher'),
        highlight: 'Lvl ${auth.level}',
        bigLabel: S.tr('hozirgi daraja', 'текущий уровень', 'current level'),
        gradient: AppColors.gradCosmic,
        isLast: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF08091A),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Progress dots
                      Row(
                        children: List.generate(slides.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == _slide ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == _slide
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: slides.length,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _slide = i);
                    },
                    itemBuilder: (_, i) => _SlideView(slide: slides[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      if (_slide > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _ctrl.previousPage(
                              duration:
                                  const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              S.tr('Oldingi', 'Назад', 'Previous'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_slide > 0) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: NebulaButton(
                          label: _slide == slides.length - 1
                              ? S.tr('Yopish', 'Закрыть', 'Close')
                              : S.tr('Keyingi', 'Далее', 'Next'),
                          icon: _slide == slides.length - 1
                              ? LucideIcons.check
                              : LucideIcons.arrowRight,
                          onTap: () {
                            if (_slide == slides.length - 1) {
                              Navigator.pop(context);
                            } else {
                              _ctrl.nextPage(
                                duration:
                                    const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _catEmoji(String c) => {
        'study': '',
        'exercise': '',
        'reading': '\u{1F4D6}',
        'meditation': '\u{1F9D8}',
        'social': '\u{1F465}',
        'creative': '\u{1F3A8}',
        'productivity': '\u26A1',
        'challenge': '\u{1F3C6}',
      }[c] ??
      '';

  String _catLabel(String c) => {
        'study': S.tr("O'qish", 'Учёба', 'Study'),
        'exercise': S.tr('Jismoniy', 'Спорт', 'Exercise'),
        'reading': S.tr('Kitob', 'Чтение', 'Reading'),
        'meditation': S.tr('Meditatsiya', 'Медитация', 'Meditation'),
        'social': S.tr('Ijtimoiy', 'Социальное', 'Social'),
        'creative': S.tr('Ijodiy', 'Творчество', 'Creative'),
        'productivity': S.tr('Samaradorlik', 'Продуктивность', 'Productivity'),
        'challenge': S.tr('Musobaqa', 'Челлендж', 'Challenge'),
      }[c] ??
      c;
}

class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final String highlight;
  final String? bigLabel;
  final List<Color> gradient;
  final bool isLast;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.highlight,
    this.bigLabel,
    required this.gradient,
    this.isLast = false,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                slide.gradient.first.withOpacity(0.5),
                slide.gradient.first.withOpacity(0.0),
              ]),
            ),
            child: Center(
              child: Text(slide.emoji,
                  style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            slide.subtitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
              slide.highlight,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.txt,
                fontSize: slide.highlight.length > 6 ? 52 : 84,
                fontWeight: FontWeight.w800,
                letterSpacing: -3,
                height: 1,
              ),
            ),
          if (slide.bigLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              slide.bigLabel!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
