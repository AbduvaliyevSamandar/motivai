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
    // Theme-aware ambient tint at the top of the screen — strong enough
    // to read at a glance ('this is Indigo / Forest / Mono'), still
    // calm enough to keep dark mode dark.
    final topTint = AppColors.primary.withOpacity(dark ? 0.32 : 0.14);
    final midTint = AppColors.primary.withOpacity(dark ? 0.14 : 0.06);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.35, 1],
          colors: [
            Color.alphaBlend(topTint, AppColors.bg),
            Color.alphaBlend(midTint, AppColors.bg),
            AppColors.bgDeep,
          ],
        ),
      ),
      child: child,
    );
  }
}
