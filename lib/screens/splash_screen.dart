import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';
import '../config/strings.dart';
import '../widgets/nebula/nebula.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _progressCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash adopts the active theme — preset switch is visible from
    // the very first frame.
    final dark = AppColors.isDark;
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.6),
                radius: 1.4,
                colors: [
                  Color.alphaBlend(
                    AppColors.primary.withOpacity(dark ? 0.35 : 0.15),
                    AppColors.bg,
                  ),
                  AppColors.bgDeep,
                ],
              ),
            ),
          ),
          const ParticleField(
              count: 40, color: Color(0x66FFFFFF)),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo in glass frame with XP ring outer decoration
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _logoRotate.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => XPRing(
                          progress: _progressCtrl.value,
                          size: 180,
                          strokeWidth: 6,
                          gradientColors: AppColors.gradAurora,
                          center: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: D.sp32),

                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFE0D4FB),
                          Color(0xFF9CE4FF),
                        ],
                      ).createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'MotivAI',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: D.sp12),

                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        S.get('motto'),
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                FadeTransition(
                  opacity: _textFade,
                  child: _LoadingBar(ctrl: _progressCtrl),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final AnimationController ctrl;
  const _LoadingBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 240,
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ctrl.value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradAurora,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: D.sp16),
        AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final pct = (ctrl.value * 100).floor();
            return Text(
              '$pct%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 2,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ],
    );
  }
}
