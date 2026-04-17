import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? D.radiusSm;

    return Shimmer.fromColors(
      baseColor: AppColors.isDark
          ? const Color(0xFF2A3A50)
          : const Color(0xFFE5E7EB),
      highlightColor: AppColors.isDark
          ? const Color(0xFF3A4A60)
          : const Color(0xFFF3F4F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
