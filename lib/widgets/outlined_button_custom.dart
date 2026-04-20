import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class OutlinedButtonCustom extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final Color? color;
  final double? height;
  final double? borderRadius;
  final bool expand;

  const OutlinedButtonCustom({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.color,
    this.height,
    this.borderRadius,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final radius = borderRadius ?? D.radiusMd;

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: D.iconMd, color: c),
                const SizedBox(width: D.sp8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ],
          );

    final btn = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height ?? 52,
          padding: const EdgeInsets.symmetric(horizontal: D.sp16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.withOpacity(0.6), width: 1.4),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
