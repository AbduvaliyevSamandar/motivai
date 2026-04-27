import 'package:flutter/material.dart';
import '../../config/colors.dart';

/// Background layer used at the bottom of every Stack-based screen.
///
/// We used to draw an animated aurora with floating colored blobs and a
/// blur. That looked AI-generated. The new look is a clean, near-flat
/// surface — just the theme's bg color, with an almost-invisible vertical
/// gradient for a touch of depth. Dropping the animation also frees up a
/// running ticker on every screen.
class AuroraBackground extends StatelessWidget {
  final Widget? child;
  final bool subtle; // kept for back-compat — ignored

  const AuroraBackground({super.key, this.child, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [AppColors.bg, AppColors.bgDeep]
              : [AppColors.bg, AppColors.bgDeep],
        ),
      ),
      child: child,
    );
  }
}
