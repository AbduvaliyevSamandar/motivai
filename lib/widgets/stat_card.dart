import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class StatCard extends StatelessWidget {
  final String emoji;
  final IconData? icon;
  final String value;
  final String label;
  final String? trend;
  final bool trendPositive;
  final List<Color>? gradient;

  const StatCard({
    super.key,
    this.emoji = '',
    this.icon,
    required this.value,
    required this.label,
    this.trend,
    this.trendPositive = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;

    return Container(
      padding: const EdgeInsets.all(D.sp16),
      decoration: BoxDecoration(
        color: hasGradient ? null : AppColors.card,
        gradient: hasGradient
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(D.radiusLg),
        border: hasGradient
            ? null
            : Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: hasGradient
                ? gradient!.first.withOpacity(0.3)
                : Colors.black.withOpacity(AppColors.isDark ? 0.2 : 0.04),
            blurRadius: hasGradient ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (emoji.isNotEmpty)
                Text(emoji, style: const TextStyle(fontSize: 24)),
              if (icon != null)
                Icon(icon,
                    size: D.iconLg,
                    color: hasGradient ? Colors.white : AppColors.primary),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trendPositive ? AppColors.success : AppColors.danger)
                        .withOpacity(hasGradient ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(D.radiusSm),
                  ),
                  child: Text(
                    trend!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasGradient
                          ? Colors.white
                          : (trendPositive
                              ? AppColors.success
                              : AppColors.danger),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: D.sp12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: hasGradient ? Colors.white : AppColors.txt,
            ),
          ),
          const SizedBox(height: D.sp4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: hasGradient
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.sub,
            ),
          ),
        ],
      ),
    );
  }
}
