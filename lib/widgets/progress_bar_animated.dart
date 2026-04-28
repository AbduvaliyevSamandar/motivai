import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class ProgressBarAnimated extends StatelessWidget {
  final double value;
  final double height;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final String? label;
  final String? trailing;
  final bool showPercent;
  final Duration duration;

  const ProgressBarAnimated({
    super.key,
    required this.value,
    this.height = 10,
    this.gradient,
    this.backgroundColor,
    this.label,
    this.trailing,
    this.showPercent = false,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final colors = gradient ?? AppColors.gradPrimary;
    final bg = backgroundColor ?? AppColors.border.withOpacity(0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || trailing != null || showPercent) ...[
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sub,
                    ),
                  ),
                ),
              Text(
                trailing ?? (showPercent ? '${(clamped * 100).toInt()}%' : ''),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.txt,
                ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            ],
          ),
          const SizedBox(height: D.sp8),
        ],
        LayoutBuilder(
          builder: (context, cons) {
            return Stack(
              children: [
                Container(
                  height: height,
                  width: cons.maxWidth,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) {
                    return Container(
                      height: height,
                      width: cons.maxWidth * v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(height),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
