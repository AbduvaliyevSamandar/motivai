import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool disabled;
  final List<Color>? gradient;
  final double? height;
  final double? borderRadius;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.disabled = false,
    this.gradient,
    this.height,
    this.borderRadius,
    this.expand = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.disabled || widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradient ?? AppColors.gradPrimary;
    final radius = widget.borderRadius ?? D.radiusMd;

    final body = AnimatedOpacity(
      opacity: _isDisabled ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: widget.height ?? 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _isDisabled
              ? null
              : [
                  BoxShadow(
                    color: colors.first.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: _isDisabled ? null : (_) => _ctrl.forward(),
            onTapUp: _isDisabled ? null : (_) => _ctrl.reverse(),
            onTapCancel: _ctrl.reverse,
            onTap: _isDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onTap?.call();
                  },
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              color: Colors.white, size: D.iconMd),
                          const SizedBox(width: D.sp8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return ScaleTransition(
      scale: _scale,
      child: widget.expand ? SizedBox(width: double.infinity, child: body) : body,
    );
  }
}
