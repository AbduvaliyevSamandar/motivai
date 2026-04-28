import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
          title: 'MotivAI ga xush kelibsiz!',
          body: 'Maqsadga har kuni bir qadam — AI bilan motivatsion reja.',
          gradient: AppColors.gradCosmic,
        ),
        _OSlide(
          emoji: '\u{1F3AF}',
          title: 'Vazifa qo\'shing',
          body: 'Vaqti, qiyinligi va eslatma bilan. Bajarsa XP oling.',
          gradient: AppColors.gradGold,
        ),
        _OSlide(
          emoji: '\u{1F525}',
          title: 'Streak saqlang',
          body: 'Har kuni ish qiling — olov o\'chirmasin! Freeze kun ham bor.',
          gradient: AppColors.gradFire,
        ),
        _OSlide(
          emoji: '\u{1F4AB}',
          title: 'Reytingda yuqorilang',
          body: 'Pomodoro, flashcards, yutuqlar — hamma sizni kuchli qiladi.',
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
          const AuroraBackground(),
          const ParticleField(count: 40),
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
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            "O'tkazib yuborish",
                            style: GoogleFonts.poppins(
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
                    label: isLast ? 'Boshlash' : 'Keyingi',
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
                  style: const TextStyle(fontSize: 100)),
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (b) =>
                LinearGradient(colors: slide.gradient).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
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
          Text('\u{1F3AF}', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: AppColors.gradCosmic,
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Asosiy maqsadingiz?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanlang — biz sizga mos reja tuzamiz',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
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
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(o.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: active
                              ? LinearGradient(colors: [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.08),
                                ])
                              : null,
                          color: active
                              ? null
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
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
                                      const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  Text(o.desc,
                                      style: GoogleFonts.poppins(
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
