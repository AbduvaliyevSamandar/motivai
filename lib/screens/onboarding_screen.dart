import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';
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
    widget.onFinish();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
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
                          _slides.length,
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
                    itemCount: _slides.length,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = i);
                    },
                    itemBuilder: (_, i) =>
                        _SlideView(slide: _slides[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: NebulaButton(
                    label: isLast ? 'Boshlash' : 'Keyingi',
                    icon: isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
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
              style: GoogleFonts.spaceGrotesk(
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
