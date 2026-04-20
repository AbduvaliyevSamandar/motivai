import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';

/// Frosted glass card with inner glow border and optional gradient stroke.
/// The signature surface of Nebula design system.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<Color>? glowColors;
  final double glowIntensity;
  final bool gradientBorder;
  final double blurStrength;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.glowColors,
    this.glowIntensity = 0.25,
    this.gradientBorder = true,
    this.blurStrength = 16,
    this.tint,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 20;
    final glowColors = widget.glowColors ??
        [AppColors.primary, AppColors.secondary];

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurStrength,
          sigmaY: widget.blurStrength,
        ),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(D.sp16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.tint != null
                  ? [
                      widget.tint!.withOpacity(0.18),
                      widget.tint!.withOpacity(0.08),
                    ]
                  : [
                      Colors.white.withOpacity(AppColors.isDark ? 0.06 : 0.5),
                      Colors.white.withOpacity(AppColors.isDark ? 0.02 : 0.3),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.gradientBorder) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              glowColors.first.withOpacity(0.5),
              glowColors.last.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1.2),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg.withOpacity(AppColors.isDark ? 0.5 : 0.3),
              borderRadius: BorderRadius.circular(radius - 1.2),
            ),
            child: card,
          ),
        ),
      );
    }

    // Glow shadow
    card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: glowColors.first.withOpacity(widget.glowIntensity * 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: glowColors.last.withOpacity(widget.glowIntensity * 0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      margin: widget.margin,
      child: card,
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: ScaleTransition(scale: _scale, child: card),
      );
    }

    return card;
  }
}
