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
    // Use spaceBetween + Flexible everywhere so content lays itself out
    // against the parent box constraints (provided by GridView via
    // childAspectRatio). No fixed margins / paddings between children
    // beyond spacers — the column stretches to whatever the card gives it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.emoji != null)
              Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
            if (widget.icon != null)
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(widget.icon, color: accent, size: 16),
              ),
            const Spacer(),
            if (widget.trend != null)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.trendPositive
                            ? AppColors.success
                            : AppColors.danger)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.trendPositive
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 10,
                        color: widget.trendPositive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.trend!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: widget.trendPositive
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value!,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.txt,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            if (widget.label != null)
              Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.sub,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
