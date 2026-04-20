import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final String? emoji;
  final VoidCallback? onTap;
  final List<Color>? selectedGradient;
  final Color? selectedColor;

  const CustomChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.emoji,
    this.onTap,
    this.selectedGradient,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final grad = selectedGradient ?? AppColors.gradPrimary;
    final accent = selectedColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: D.sp16, vertical: D.sp8 + 2),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(D.radiusXl),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: D.iconSm,
                color: selected ? Colors.white : AppColors.sub,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.txt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
