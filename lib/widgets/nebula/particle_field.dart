import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/colors.dart';

/// Subtle floating particles for background depth.
class ParticleField extends StatefulWidget {
  final int count;
  final Color? color;

  const ParticleField({
    super.key,
    this.count = 28,
    this.color,
  });

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late List<_P> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(
      widget.count,
      (_) => _P(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: 1 + rng.nextDouble() * 2.5,
        speed: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * 2 * math.pi,
      ),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            t: _ctrl.value,
            color: widget.color ??
                (AppColors.isDark
                    ? Colors.white.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.3)),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _P {
  final double x, y, r, speed, phase;
  _P({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_P> particles;
  final double t;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yDrift = 30 * math.sin(p.phase + t * 2 * math.pi * p.speed);
      final xDrift = 15 * math.cos(p.phase + t * 2 * math.pi * p.speed * 0.5);
      final twinkle =
          0.4 + 0.6 * (0.5 + 0.5 * math.sin(p.phase + t * 4 * math.pi));
      final paint = Paint()
        ..color = color.withOpacity(color.opacity * twinkle);
      canvas.drawCircle(
        Offset(
          p.x * size.width + xDrift,
          p.y * size.height + yDrift,
        ),
        p.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
