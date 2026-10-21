import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipe.dart';
import '../../repositories/nutrition_service.dart';
import '../colors.dart';
import '../sprout_haptics.dart';
import '../typography.dart';
import 'sprout_diet_badge.dart';
import 'sprout_recipe_image.dart';

/// Editorial 2-column grid recipe card inspired by Reference 2,
/// featuring warm ivory surfaces, rounded image crop, Fraunces serif title,
/// diet indicator, cooking time, and protein/carb/fat macro breakdown.
class SproutGridRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String heroTagPrefix;
  final Widget Function(BuildContext, VoidCallback)? openBuilder;

  const SproutGridRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteToggle,
    this.heroTagPrefix = 'recipe_image_explore',
    this.openBuilder,
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
    final isVeg = widget.recipe.diet.toLowerCase() == 'veg' ||
        widget.recipe.diet.toLowerCase() == 'vegetarian';
    final isEgg = widget.recipe.diet.toLowerCase() == 'egg';
    final dotColor = isVeg
        ? const Color(0xFF2E7D32)
        : (isEgg ? const Color(0xFFE65100) : const Color(0xFFE53935));

    final nutrition = NutritionService.calculateHeuristicNutrition(widget.recipe);

    final badgeText = nutrition.calories > 0
        ? '${nutrition.calories} kcal'
        : (widget.recipe.totalTimeMins > 0 ? '${widget.recipe.totalTimeMins} min' : '20 min');

    Widget cardContent(VoidCallback? openAction) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
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
                      borderRadius: BorderRadius.circular(14),
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
                    top: 8,
                    right: 8,
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
                                  color: Colors.white.withValues(alpha: 0.82),
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
                                        : const Color(0xFF24352A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Dark Frosted Glass Badge (Calorie / Time)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
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
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
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

            const SizedBox(height: 8),

            // Title: Editorial Serif Fraunces
            Text(
              widget.recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fraunces(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 4),

            // Diet status badge + Cuisine & Time
            Row(
              children: [
                SproutDietBadge(
                  diet: widget.recipe.diet,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${widget.recipe.cuisine} • ${widget.recipe.totalTimeMins > 0 ? '${widget.recipe.totalTimeMins} min' : '20 min'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SproutTypography.caption(
                      color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                    ).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Dietary & Macro Row: dot + protein/carbs/fat
            Row(
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${nutrition.proteinG}g P • ${nutrition.carbsG}g C • ${nutrition.fatG}g F',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SproutTypography.caption(
                      color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                    ).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (widget.openBuilder != null) {
      return Semantics(
        container: true,
        button: true,
        label: 'Recipe: ${widget.recipe.title}, ${widget.recipe.cuisine}',
        child: OpenContainer(
          closedElevation: 0,
          closedColor: Colors.transparent,
          openElevation: 0,
          openColor: Theme.of(context).scaffoldBackgroundColor,
          middleColor: Theme.of(context).scaffoldBackgroundColor,
          transitionDuration: const Duration(milliseconds: 380),
          closedBuilder: (context, action) => cardContent(action),
          openBuilder: (context, action) => widget.openBuilder!(context, action),
        ),
      );
    }

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
        child: cardContent(null),
      ),
    );
  }
}
