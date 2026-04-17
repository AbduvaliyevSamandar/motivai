import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final List<Color>? gradient;
  final Border? border;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.padding,
    this.margin,
    this.shadow,
    this.onTap,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) _ctrl.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? D.radiusLg;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.all(D.sp16),
          decoration: BoxDecoration(
            color: widget.gradient != null ? null : (widget.color ?? AppColors.card),
            gradient: widget.gradient != null
                ? LinearGradient(
                    colors: widget.gradient!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(radius),
            border: widget.border ??
                Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: widget.shadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(AppColors.isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
