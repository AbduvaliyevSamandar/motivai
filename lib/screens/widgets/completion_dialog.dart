import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';
import '../../widgets/nebula/nebula.dart';

class CompletionDialog extends StatefulWidget {
  final Map<String, dynamic> result;
  final String taskTitle;

  const CompletionDialog({
    super.key,
    required this.result,
    required this.taskTitle,
  });

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _confetti;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);

    _entry.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _confetti.forward();
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final xpEarned = (r['xp_earned'] ?? r['points_earned'] ?? 0) as int;
    final newLevel = r['new_level'] ?? r['level'];
    final levelUp = r['level_up'] == true;
    final streak = (r['current_streak'] ?? r['streak'] ?? 0) as int;
    final newBadges =
        ((r['new_badges'] ?? r['new_achievements']) as List?) ?? [];

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti layer
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) => CustomPaint(
                  size: const Size(400, 500),
                  painter: _ConfettiPainter(
                    progress: _confetti.value,
                    levelUp: levelUp,
                  ),
                ),
              ),
            ),
            // Dialog card
            ScaleTransition(
              scale: _scale,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: levelUp
                        ? [
                            const Color(0xFF1A1340),
                            const Color(0xFF2A1558),
                          ]
                        : [
                            AppColors.card,
                            Color.lerp(AppColors.card, AppColors.primary,
                                0.08)!,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: levelUp
                        ? AppColors.accent.withOpacity(0.6)
                        : AppColors.primary.withOpacity(0.4),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (levelUp
                              ? AppColors.accent
                              : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with pulse
                    _PulseIcon(levelUp: levelUp),
                    const SizedBox(height: 14),

                    // Title
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: levelUp
                            ? AppColors.gradGold
                            : AppColors.gradSuccess,
                      ).createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        levelUp ? 'DARAJA O\'SDI!' : 'VAZIFA BAJARILDI!',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      widget.taskTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.txt.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // XP big display
                    if (xpEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.accent.withOpacity(0.25),
                            AppColors.accent.withOpacity(0.1),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: AppColors.accent, size: 28),
                            const SizedBox(width: 10),
                            BigNumber(
                              value: '+$xpEarned',
                              label: 'XP',
                              size: 38,
                              gradient: AppColors.gradGold,
                              align: TextAlign.start,
                            ),
                          ],
                        ),
                      ),

                    if (levelUp && newLevel != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: AppColors.gradCosmic),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withOpacity(0.5),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Daraja $newLevel',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (streak > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('\u{1F525}',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '$streak kunlik streak',
                              style: GoogleFonts.poppins(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (newBadges.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        '\u{1F3C6} Yangi yutuqlar: ${newBadges.length}',
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    NebulaButton(
                      label: "Davom etish",
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final bool levelUp;
  const _PulseIcon({required this.levelUp});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: 1.0 + 0.08 * _ctrl.value,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.levelUp
                  ? AppColors.gradGold
                  : AppColors.gradSuccess,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.levelUp
                        ? AppColors.accent
                        : AppColors.success)
                    .withOpacity(0.55 + 0.2 * _ctrl.value),
                blurRadius: 20 + 10 * _ctrl.value,
                spreadRadius: 2 + _ctrl.value * 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.levelUp ? '\u{1F451}' : '\u{2705}',
              style: const TextStyle(fontSize: 38),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final bool levelUp;
  _ConfettiPainter({required this.progress, required this.levelUp});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final rng = math.Random(42);
    final count = levelUp ? 36 : 20;
    final colors = levelUp
        ? [AppColors.accent, AppColors.primary, AppColors.secondary, AppColors.pink]
        : [AppColors.success, AppColors.accent, AppColors.primary];

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final distance = 60 + rng.nextDouble() * 160;
      final travel = distance * Curves.easeOutCubic.transform(progress);
      final fall = 80 * progress * progress;

      final x = cx + math.cos(angle) * travel;
      final y = cy + math.sin(angle) * travel + fall;

      final color =
          colors[rng.nextInt(colors.length)].withOpacity(1 - progress);
      final size0 = 3 + rng.nextDouble() * 5;

      final paint = Paint()..color = color;
      if (rng.nextBool()) {
        canvas.drawCircle(Offset(x, y), size0, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle * 2 + progress * 6);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size0 * 1.4,
            height: size0 * 0.6,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
