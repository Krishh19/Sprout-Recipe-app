import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/recipe.dart';
import '../../repositories/nutrition_service.dart';
import '../colors.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';
import 'sprout_recipe_image.dart';
import 'sprout_shimmer.dart';

/// A modern minimal 2-column grid recipe card with a borderless design,
/// 1:1 rounded square image, frosted glass overlays, and clean sans-serif typography.
class SproutGridRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String heroTagPrefix;

  const SproutGridRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteToggle,
    this.heroTagPrefix = 'recipe_image_explore',
  });

  @override
  State<SproutGridRecipeCard> createState() => _SproutGridRecipeCardState();
}

class _SproutGridRecipeCardState extends State<SproutGridRecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleFavorite() {
    SproutHaptics.selection();
    _heartController.forward(from: 0.0);
    widget.onFavoriteToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final isVegetarian = widget.recipe.diet.toLowerCase() == 'veg' ||
        widget.recipe.diet.toLowerCase() == 'vegetarian';
    final nutrition = NutritionService.calculateHeuristicNutrition(widget.recipe);

    final badgeText = nutrition.calories > 0
        ? '${nutrition.calories} kcal'
        : (widget.recipe.totalTimeMins > 0 ? '${widget.recipe.totalTimeMins} min' : '20 min');

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: 'Recipe: ${widget.recipe.title}, ${widget.recipe.cuisine}',
      child: GestureDetector(
        onTap: () {
          SproutHaptics.light();
          widget.onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1:1 Aspect Ratio Image Container with Overlays
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Rounded Image
                  Hero(
                    tag: '${widget.heroTagPrefix}_${widget.recipe.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SproutRecipeImage(
                        imageUrl: widget.recipe.imageUrl,
                        cuisine: widget.recipe.cuisine,
                        title: widget.recipe.title,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Top-Right Frosted Glass Favorite Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _handleFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        button: true,
                        toggled: widget.recipe.isSaved,
                        label: widget.recipe.isSaved
                            ? 'Remove ${widget.recipe.title} from favorites'
                            : 'Save ${widget.recipe.title} to favorites',
                        child: ScaleTransition(
                          scale: _heartScale,
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    widget.recipe.isSaved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 17,
                                    color: widget.recipe.isSaved
                                        ? SproutColors.tomato
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Dark Frosted Glass Badge
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nutrition.calories > 0 ? '🔥' : '⏱',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 8px Spacing below image
            const SizedBox(height: 8),

            // Title: Clean sans-serif, single line with ellipsis
            Text(
              widget.recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SproutTypography.bodyBold().copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),

            // Subtitle: Cuisine & Time (2px top margin)
            const SizedBox(height: 2),
            Text(
              '${widget.recipe.cuisine} • ${widget.recipe.totalTimeMins > 0 ? '${widget.recipe.totalTimeMins} min' : '20 min'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SproutTypography.small().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF757575),
                height: 1.25,
              ),
            ),

            // Dietary & Macro Row: 4px top margin
            const SizedBox(height: 4),
            Row(
              children: [
                // Dietary status dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isVegetarian
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                  ),
                ),
                const SizedBox(width: 5),

                // Macros breakdown
                Expanded(
                  child: Text(
                    '${nutrition.proteinG}g P • ${nutrition.carbsG}g C • ${nutrition.fatG}g F',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SproutTypography.caption().copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton loader for SproutGridRecipeCard matching exact 2-column dimensions.
class SproutGridRecipeCardSkeleton extends StatelessWidget {
  const SproutGridRecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SproutColors.sage.withValues(alpha: 0.18),
      highlightColor: SproutColors.surface,
      period: const Duration(milliseconds: 1400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1:1 Aspect Ratio Image Shimmer
          AspectRatio(
            aspectRatio: 1.0,
            child: SproutShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 8),

          // Title Shimmer
          const SproutShimmerBox(
            width: 120,
            height: 15,
            borderRadius: SproutRadii.borderSm,
          ),
          const SizedBox(height: 4),

          // Subtitle Shimmer
          const SproutShimmerBox(
            width: 80,
            height: 12,
            borderRadius: SproutRadii.borderSm,
          ),
          const SizedBox(height: 4),

          // Macro Shimmer
          const SproutShimmerBox(
            width: 100,
            height: 10,
            borderRadius: SproutRadii.borderSm,
          ),
        ],
      ),
    );
  }
}
