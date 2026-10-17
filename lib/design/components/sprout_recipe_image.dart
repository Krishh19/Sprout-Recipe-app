import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../colors.dart';
import '../food_image_helper.dart';
import '../radii.dart';
import '../sprout_assets.dart';
import '../typography.dart';

class SproutRecipeImage extends StatelessWidget {
  final String? imageUrl;
  final String cuisine;
  final String? title;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool isDetail;

  const SproutRecipeImage({
    super.key,
    required this.imageUrl,
    required this.cuisine,
    this.title,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.zero;
    final fallbackWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        color: SproutColors.sage.withValues(alpha: 0.08),
        child: Image.asset(
          SproutAssets.imageNotFound,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => CuisinePlaceholder(
            cuisine: cuisine,
            width: width,
            height: height,
            borderRadius: effectiveRadius,
            isCompact: (height != null && height! <= 90),
          ),
        ),
      ),
    );

    final validUrl = FoodImageHelper.getValidImageUrl(
      originalUrl: imageUrl,
      title: title ?? '',
      cuisine: cuisine,
    );

    if (validUrl == null || !validUrl.startsWith('http')) {
      return fallbackWidget;
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: validUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: isDetail ? 1200 : 600,
        fadeInDuration: const Duration(milliseconds: 250),
        fadeInCurve: Curves.easeOut,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: SproutColors.canvas,
          highlightColor: SproutColors.elevatedSurface,
          child: Container(
            width: width,
            height: height,
            color: SproutColors.canvas,
          ),
        ),
        errorWidget: (context, url, error) => fallbackWidget,
      ),
    );
  }
}

class CuisinePlaceholder extends StatelessWidget {
  final String cuisine;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final bool isCompact;

  const CuisinePlaceholder({
    super.key,
    required this.cuisine,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.isCompact = false,
  });

  Color _getCuisineTint(String c) {
    final lower = c.toLowerCase();
    if (lower.contains('north indian') || lower.contains('punjabi') || lower.contains('mughlai')) {
      return const Color(0xFFFFF3E0); // Warm saffron/amber tint
    }
    if (lower.contains('south indian') || lower.contains('kerala') || lower.contains('tamil')) {
      return const Color(0xFFE8F5E9); // Fresh banana-leaf sage tint
    }
    if (lower.contains('italian') || lower.contains('mexican')) {
      return const Color(0xFFFBE9E7); // Warm terracotta tint
    }
    if (lower.contains('dessert') || lower.contains('sweet')) {
      return const Color(0xFFFFF8E1); // Soft vanilla tint
    }
    if (lower.contains('asian') || lower.contains('chinese') || lower.contains('thai')) {
      return const Color(0xFFE0F2F1); // Teal herbal tint
    }
    return SproutColors.sage.withValues(alpha: 0.15);
  }

  IconData _getCuisineIcon(String c) {
    final lower = c.toLowerCase();
    if (lower.contains('dessert') || lower.contains('sweet')) {
      return Icons.cake_outlined;
    }
    if (lower.contains('italian')) {
      return Icons.local_pizza_outlined;
    }
    if (lower.contains('salad') || lower.contains('healthy')) {
      return Icons.eco_outlined;
    }
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tint = _getCuisineTint(cuisine);
    final icon = _getCuisineIcon(cuisine);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(
            color: SproutColors.sage.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Mascot illustration or culinary glyph
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  SproutAssets.mascotIdle,
                  width: isCompact ? 36 : 60,
                  height: isCompact ? 36 : 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    icon,
                    size: isCompact ? 28 : 44,
                    color: SproutColors.sproutGreen,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: SproutColors.surface.withValues(alpha: 0.85),
                      borderRadius: SproutRadii.borderPill,
                      border: Border.all(
                        color: SproutColors.sage.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      cuisine.isNotEmpty ? cuisine : 'Sprout Recipe',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SproutTypography.caption(
                        color: SproutColors.secondaryInk,
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
