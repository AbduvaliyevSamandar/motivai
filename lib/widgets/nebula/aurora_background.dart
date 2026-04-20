import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/colors.dart';

/// Animated aurora gradient background with drifting blobs.
/// Place as the deepest layer in a Stack.
class AuroraBackground extends StatefulWidget {
  final Widget? child;
  final bool subtle;

  const AuroraBackground({
    super.key,
    this.child,
    this.subtle = false,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.subtle ? 0.5 : 1.0;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Violet blob (top-left, drifts diagonally)
              Positioned(
                top: -120 + 60 * _sin(t * 2 * 3.14159),
                left: -100 + 40 * _cos(t * 2 * 3.14159),
                child: _blob(
                  320,
                  AppColors.primary.withOpacity(0.35 * op),
                ),
              ),
              // Cyan blob (right, vertical drift)
              Positioned(
                top: 160 + 80 * _cos(t * 2 * 3.14159 + 1),
                right: -80 + 30 * _sin(t * 2 * 3.14159 + 0.5),
                child: _blob(
                  280,
                  AppColors.secondary.withOpacity(0.25 * op),
                ),
              ),
              // Pink blob (bottom-left)
              Positioned(
                bottom: -120 + 40 * _sin(t * 2 * 3.14159 + 2),
                left: -60 + 50 * _cos(t * 2 * 3.14159 + 2),
                child: _blob(
                  300,
                  AppColors.pink.withOpacity(0.22 * op),
                ),
              ),
              // Gold blob (bottom-right)
              Positioned(
                bottom: 40 + 30 * _cos(t * 2 * 3.14159 + 3),
                right: -100 + 60 * _sin(t * 2 * 3.14159 + 3),
                child: _blob(
                  240,
                  AppColors.accent.withOpacity(0.18 * op),
                ),
              ),
              // Blur layer — softens the whole aurora
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  // Simple sin/cos approximations (no dart:math import needed via Curves)
  double _sin(double x) {
    // Use built-in math via Offset rotation — but simpler: just use a direct formula
    // Dart's sin() IS available via dart:math
    return _mathSin(x);
  }

  double _cos(double x) => _mathSin(x + 1.5708);

  double _mathSin(double x) {
    // Normalize to [-pi, pi]
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    // Taylor series (5 terms) — good enough
    final x2 = x * x;
    final x3 = x * x2;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    return x - x3 / 6 + x5 / 120 - x7 / 5040;
  }
}
