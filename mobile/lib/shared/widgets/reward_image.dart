import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';

/// Product artwork for a reward.
///
/// The catalogue stores the bare file name (`reward_coffee.jpg`), and the
/// picture itself ships in the app bundle: the reward list therefore renders
/// instantly and still works offline. Artwork missing from the bundle (or a
/// blank `image_asset`) degrades to the gift glyph rather than a broken box.
class RewardImage extends StatelessWidget {
  const RewardImage({
    super.key,
    required this.imageAsset,
    this.width,
    this.height,
    this.borderRadius = AppRadius.lg,
    this.fit = BoxFit.cover,
  });

  /// `rewards.image_asset` as returned by the API.
  final String imageAsset;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  static const assetDirectory = 'assets/images/';

  /// Resolves the catalogue value to a bundle path, or null when there is
  /// nothing to draw.
  String? get resolvedAsset {
    final name = imageAsset.trim();
    if (name.isEmpty) return null;
    return name.contains('/') ? name : '$assetDirectory$name';
  }

  @override
  Widget build(BuildContext context) {
    final path = resolvedAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: path == null
            ? _fallback()
            : Image.asset(
                path,
                fit: fit,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    final side = height;
    final iconSize = side == null || !side.isFinite
        ? 44.0
        : (side * 0.45).clamp(20.0, 56.0).toDouble();
    return ColoredBox(
      color: AppColors.accentLight,
      child: Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          color: AppColors.primaryNavy,
          size: iconSize,
        ),
      ),
    );
  }
}
