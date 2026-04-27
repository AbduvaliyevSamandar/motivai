import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';

/// Container with a flat surface color and a thin border.
///
/// The original implementation layered a backdrop-filter blur, a gradient
/// stroke and outer glow shadows on every card. That gave the app the
/// AI-generated "premium" look the user wanted to drop. The new card is
/// the same shape and same API but flat.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<Color>? glowColors;     // back-compat — ignored
  final double glowIntensity;        // back-compat — ignored
  final bool gradientBorder;         // back-compat — ignored
  final double blurStrength;         // back-compat — ignored
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.glowColors,
    this.glowIntensity = 0,
    this.gradientBorder = false,
    this.blurStrength = 0,
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
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.985).animate(
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
    final radius = widget.borderRadius ?? 16;
    final dark = AppColors.isDark;
    final bg = widget.tint != null
        ? widget.tint!.withOpacity(dark ? 0.10 : 0.06)
        : AppColors.surface;
    final borderColor = widget.tint != null
        ? widget.tint!.withOpacity(dark ? 0.25 : 0.15)
        : AppColors.border;

    Widget card = Container(
      padding: widget.padding ?? const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: widget.child,
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: ScaleTransition(scale: _scale, child: card),
      );
    }

    return card;
  }
}
