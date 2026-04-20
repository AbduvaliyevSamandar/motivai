import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';

/// Apple Fitness-style huge display number with gradient.
class BigNumber extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final double size;
  final List<Color>? gradient;
  final TextAlign align;

  const BigNumber({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.size = 64,
    this.gradient,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppColors.gradCosmic;
    return Column(
      crossAxisAlignment: align == TextAlign.start
          ? CrossAxisAlignment.start
          : align == TextAlign.end
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: align,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  letterSpacing: -2,
                  foreground: Paint()
                    ..shader = LinearGradient(colors: grad).createShader(
                      Rect.fromLTWH(0, 0, 400, size),
                    ),
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.sub,
                    letterSpacing: -0.3,
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!.toUpperCase(),
            textAlign: align,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.sub,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ],
    );
  }
}
