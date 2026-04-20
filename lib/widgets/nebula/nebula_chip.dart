import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';

class NebulaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final String? emoji;
  final VoidCallback? onTap;
  final List<Color>? activeGradient;

  const NebulaChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.emoji,
    this.onTap,
    this.activeGradient,
  });

  @override
  Widget build(BuildContext context) {
    final grad = activeGradient ?? AppColors.gradCosmic;

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected
              ? null
              : AppColors.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: grad.first.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                size: 14,
                color: selected ? Colors.white : AppColors.sub,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.txt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
