import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../services/journey_storage.dart';
import '../../widgets/nebula/nebula.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  List<JourneyDay> _days = [];
  int _productive = 0;
  int _focusTotal = 0;
  int _tasksTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _load();
  }

  Future<void> _load() async {
    final days = await JourneyStorage.last30Days();
    int p = 0, f = 0, t = 0;
    for (final d in days) {
      if (d.tasksDone > 0 || d.focusMinutes > 0) p++;
      f += d.focusMinutes;
      t += d.tasksDone;
    }
    if (!mounted) return;
    setState(() {
      _days = days;
      _productive = p;
      _focusTotal = f;
      _tasksTotal = t;
      _loading = false;
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: AppColors.titleGradient,
          ).createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Sayohat',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 30),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: AnimatedBuilder(
                            animation: _ctrl,
                            builder: (_, __) => CustomPaint(
                              painter: _TreePainter(
                                progress: _ctrl.value,
                                stage: _productive,
                                primary: AppColors.primary,
                                secondary: AppColors.success,
                                accent: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _progressCard(),
                        const SizedBox(height: 20),
                        _stats(),
                        const SizedBox(height: 20),
                        _calendar(),
                        const SizedBox(height: 20),
                        _lessonCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final pct = (_productive / 30).clamp(0.0, 1.0);
    String stageName;
    if (_productive < 3) {
      stageName = 'Urug\' \u{1F331}';
    } else if (_productive < 7) {
      stageName = 'Niholcha \u{1F343}';
    } else if (_productive < 14) {
      stageName = 'Yosh daraxt \u{1F333}';
    } else if (_productive < 21) {
      stageName = 'Gullagan \u{1F338}';
    } else {
      stageName = 'Mevali daraxt \u{1F332}';
    }
    return GlassCard(
      padding: const EdgeInsets.all(18),
      glowColors: [AppColors.success, AppColors.primary],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                stageName,
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                '$_productive / 30',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _productive >= 30
                ? 'Sayohat to\'ldi! Yangi urug\' tanlash vaqti.'
                : 'Yana ${30 - _productive} kun ish qilib daraxtni gullattring.',
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(
            child: _statBox(
                '$_tasksTotal', 'Vazifa', Icons.check_circle_rounded,
                AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _statBox(
                '${_focusTotal}m', 'Fokus', Icons.timer_rounded,
                AppColors.secondary)),
        const SizedBox(width: 10),
        Expanded(
            child: _statBox('$_productive', 'Faol kun',
                Icons.local_fire_department_rounded, AppColors.accent)),
      ],
    );
  }

  Widget _statBox(String v, String l, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(i, color: c, size: 20),
          const SizedBox(height: 6),
          Text(v,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              )),
          Text(l,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 10,
              )),
        ],
      ),
    );
  }

  Widget _calendar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oxirgi 30 kun',
              style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _days.map((d) {
              final score = d.tasksDone + (d.focusMinutes ~/ 20);
              final c = score == 0
                  ? AppColors.border
                  : score < 2
                      ? AppColors.success.withOpacity(0.4)
                      : score < 4
                          ? AppColors.success.withOpacity(0.7)
                          : AppColors.success;
              return Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _lessonCard() {
    final messages = [
      'Har kuni 1% ish — 1 yilda 37x o\'sish.',
      'Streak — eng kuchli motivatsiya.',
      'Kichik qadamlar katta daraxt yaratadi.',
      'Har bargda — siz qilgan bir vazifa.',
    ];
    final msg = messages[DateTime.now().day % messages.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.2),
          AppColors.secondary.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final double progress; // 0..1
  final int stage;       // 0..30
  final Color primary;
  final Color secondary;
  final Color accent;

  _TreePainter({
    required this.progress,
    required this.stage,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondary.withOpacity(0.0),
          secondary.withOpacity(0.15),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), ground);

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.88), width: w * 0.7, height: 18),
      Paint()..color = secondary.withOpacity(0.15),
    );

    // Tree height scales with stage
    final maxH = h * 0.65;
    final treeH = maxH * (stage / 30).clamp(0.15, 1.0) * progress;
    final rootX = w / 2;
    final rootY = h * 0.82;
    final topY = rootY - treeH;

    // Trunk
    final trunkW = 6 + (stage / 30) * 16;
    final trunkPath = Path()
      ..moveTo(rootX - trunkW / 2, rootY)
      ..quadraticBezierTo(rootX - trunkW / 4, (rootY + topY) / 2,
          rootX - trunkW / 3, topY)
      ..lineTo(rootX + trunkW / 3, topY)
      ..quadraticBezierTo(rootX + trunkW / 4, (rootY + topY) / 2,
          rootX + trunkW / 2, rootY)
      ..close();
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [const Color(0xFF4A2C1A), const Color(0xFF8B5A3C)],
        ).createShader(Rect.fromLTWH(rootX - trunkW, topY, trunkW * 2, treeH)),
    );

    // Canopy
    if (stage >= 3) {
      final canopyR = (treeH * 0.55).clamp(30.0, w * 0.5);
      _drawCanopy(canvas, Offset(rootX, topY), canopyR);
    }

    // Sprout emoji fallback when tiny
    if (stage < 3) {
      final tp = TextPainter(
        text: const TextSpan(
            text: '\u{1F331}', style: TextStyle(fontSize: 40)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(rootX - tp.width / 2, topY - tp.height * 0.8));
    }

    // Flowers when >= 14
    if (stage >= 14) {
      _drawFlowers(canvas, Offset(rootX, topY), w);
    }

    // Fruits when >= 21
    if (stage >= 21) {
      _drawFruits(canvas, Offset(rootX, topY), w);
    }
  }

  void _drawCanopy(Canvas canvas, Offset top, double r) {
    final rng = math.Random(42);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6BCF7F),
          const Color(0xFF2E8B57),
        ],
      ).createShader(Rect.fromCircle(center: top, radius: r * progress));

    // Draw multiple blobs
    final blobs = (stage / 4).floor().clamp(3, 9);
    for (int i = 0; i < blobs; i++) {
      final ang = (i / blobs) * math.pi * 2;
      final dist = r * 0.55 * progress;
      final cx = top.dx + math.cos(ang) * dist;
      final cy = top.dy + math.sin(ang) * dist * 0.7;
      final br = r * 0.55 * progress * (0.7 + rng.nextDouble() * 0.4);
      canvas.drawCircle(Offset(cx, cy), br, paint);
    }
    canvas.drawCircle(top, r * progress * 0.9, paint);
  }

  void _drawFlowers(Canvas canvas, Offset top, double w) {
    final rng = math.Random(7);
    final count = ((stage - 13) * 1.5).floor().clamp(2, 10);
    for (int i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * 70 + 20;
      final cx = top.dx + math.cos(ang) * dist;
      final cy = top.dy + math.sin(ang) * dist * 0.7;
      canvas.drawCircle(
        Offset(cx, cy),
        4 * progress,
        Paint()..color = accent,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2 * progress,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawFruits(Canvas canvas, Offset top, double w) {
    final rng = math.Random(17);
    final count = ((stage - 20) * 0.7).floor().clamp(1, 8);
    for (int i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * 80 + 15;
      final cx = top.dx + math.cos(ang) * dist;
      final cy = top.dy + math.sin(ang) * dist * 0.7;
      canvas.drawCircle(
        Offset(cx, cy),
        5 * progress,
        Paint()..color = const Color(0xFFFF5E6C),
      );
      canvas.drawCircle(
        Offset(cx - 1, cy - 1),
        1.5 * progress,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.progress != progress || old.stage != stage;
}
