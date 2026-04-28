import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/colors.dart';

/// Apple Fitness-style XP progress ring with gradient stroke + glow.
/// Animates from 0 to [progress] on mount.
class XPRing extends StatefulWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final List<Color>? gradientColors;
  final Widget? center;
  final Duration animDuration;

  const XPRing({
    super.key,
    required this.progress,
    this.size = 180,
    this.strokeWidth = 14,
    this.gradientColors,
    this.center,
    this.animDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<XPRing> createState() => _XPRingState();
}

class _XPRingState extends State<XPRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.animDuration,
    );
    _anim = Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0))
        .animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant XPRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? AppColors.gradCosmic;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            progress: _anim.value,
            strokeWidth: widget.strokeWidth,
            gradientColors: colors,
            bgColor: AppColors.border.withOpacity(0.4),
          ),
          child: Center(child: widget.center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Main ring with single solid stroke (no outer glow, no end dot —
    // the user wanted shadows toned down everywhere).
    final mainPaint = Paint()
      ..color = gradientColors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      mainPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.gradientColors != gradientColors ||
      old.strokeWidth != strokeWidth;
}
