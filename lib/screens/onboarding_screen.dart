import 'package:flutter/material.dart';
import '../../config/strings.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../config/colors.dart';
import '../services/user_goal.dart';
import '../widgets/nebula/nebula.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool('motivai_onboarding_done') ?? false);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  String? _selectedGoal;

  int get _pageCount => _slides.length + 1; // +1 for goal picker page

  List<_OSlide> get _slides => [
        _OSlide(
          emoji: '\u{1F31F}',
          title: S.get('welcome_to_motivai'),
          body: S.get('ai_step_motto'),
          gradient: AppColors.gradCosmic,
        ),
        _OSlide(
          emoji: '',
          title: S.get('tasks_add_first'),
          body: S.tr('Vaqti, qiyinligi va eslatma bilan. Bajarsa XP oling.', 'С временем, сложностью и напоминанием. Получайте XP за выполнение.', 'With time, difficulty and reminder. Earn XP on completion.'),
          gradient: AppColors.gradGold,
        ),
        _OSlide(
          emoji: '\u{1F525}',
          title: S.get('wrapped_streak'),
          body: S.tr('Har kuni ish qiling — olov o\'chirmasin! Freeze kun ham bor.', 'Работайте каждый день — не дайте огню погаснуть! Есть и Freeze день.', 'Work every day — keep the fire alive! Freeze days available.'),
          gradient: AppColors.gradFire,
        ),
        _OSlide(
          emoji: '',
          title: S.get('goal_rating'),
          body: S.tr('Pomodoro, flashcards, yutuqlar — hamma sizni kuchli qiladi.', 'Pomodoro, флешкарты, достижения — всё делает вас сильнее.', 'Pomodoro, flashcards, achievements — all make you stronger.'),
          gradient: AppColors.gradAurora,
        ),
      ];

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('motivai_onboarding_done', true);
    if (_selectedGoal != null) {
      await UserGoal.set(_selectedGoal!);
    }
    widget.onFinish();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    final onGoalPage = _page == _slides.length;
    final canAdvance = !onGoalPage || _selectedGoal != null;
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
                      // Progress dots
                      Row(
                        children: List.generate(
                          _pageCount,
                          (i) => AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 220),
                            width: i == _page ? 18 : 6,
                            height: 6,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            S.get('skip_btn'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pageCount,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = i);
                    },
                    itemBuilder: (_, i) {
                      if (i < _slides.length) {
                        return _SlideView(slide: _slides[i]);
                      }
                      return _GoalPicker(
                        selected: _selectedGoal,
                        onSelect: (id) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedGoal = id);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: NebulaButton(
                    label: isLast ? S.tr('Boshlash', 'Начать', 'Start') : S.tr('Keyingi', 'Далее', 'Next'),
                    icon: isLast
                        ? Iconsax.send_2
                        : LucideIcons.arrowRight,
                    disabled: !canAdvance,
                    onTap: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _ctrl.nextPage(
                          duration: const Duration(milliseconds: 260),
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
    );
  }

}

class _OSlide {
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;
  const _OSlide({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });
}

class _SlideView extends StatelessWidget {
  final _OSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
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
          const SizedBox(height: 32),
          Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _GoalPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = UserGoal.options();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('\u{1F3AF}', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 14),
          Text(
              S.get('primary_goal_q'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            S.get('tap_we_plan'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (_, i) {
                final o = options[i];
                final active = o.id == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect(o.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withOpacity(0.14)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? Colors.white.withOpacity(0.8)
                                : Colors.white.withOpacity(0.15),
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Text(o.emoji,
                                  style:
                                      const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  Text(o.desc,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.65),
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                            if (active)
                              const Icon(LucideIcons.checkCircle2,
                                  color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
