import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';

/// Bento-style card — Apple keynote layout card with gradient accent.
class BentoCard extends StatefulWidget {
  final String? label;
  final String? value;
  final IconData? icon;
  final String? emoji;
  final List<Color>? gradient;
  final Color? accent;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;
  final Widget? customChild;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool dark;

  const BentoCard({
    super.key,
    this.label,
    this.value,
    this.icon,
    this.emoji,
    this.gradient,
    this.accent,
    this.trend,
    this.trendPositive = true,
    this.onTap,
    this.customChild,
    this.height,
    this.padding,
    this.dark = true,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard>
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
    _scale =
        Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ??
        (widget.gradient?.first ?? AppColors.primary);
    final gradient = widget.gradient ?? AppColors.gradPrimary;

    Widget body = Container(
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: widget.customChild ?? _buildDefault(accent, gradient),
    );

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _ctrl.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: ScaleTransition(scale: _scale, child: body),
    );
  }

  Widget _buildDefault(Color accent, List<Color> gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.emoji != null)
              Text(widget.emoji!, style: const TextStyle(fontSize: 22)),
            if (widget.icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: accent, size: 18),
              ),
            const Spacer(),
            if (widget.trend != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (widget.trendPositive
                          ? AppColors.success
                          : AppColors.danger)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.trendPositive
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 11,
                      color: widget.trendPositive
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.trend!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.trendPositive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: D.sp12),
        if (widget.value != null)
          ShaderMask(
            shaderCallback: (r) =>
                LinearGradient(colors: gradient).createShader(r),
            blendMode: BlendMode.srcIn,
            child: Text(
              widget.value!,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
          ),
        if (widget.label != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.sub,
            ),
          ),
        ],
      ],
    );
  }
}
