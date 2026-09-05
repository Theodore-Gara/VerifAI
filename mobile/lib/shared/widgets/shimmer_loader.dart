import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
    this.margin,
  });

  ShimmerLoader.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = BorderRadius.circular(size / 2);

  const ShimmerLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.background,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.background,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const ShimmerCard(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}