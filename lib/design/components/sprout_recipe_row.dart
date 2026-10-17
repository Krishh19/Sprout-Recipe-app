import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../colors.dart';
import '../radii.dart';
import '../typography.dart';
import 'sprout_diet_badge.dart';
import 'sprout_recipe_image.dart';

class SproutRecipeRow extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const SproutRecipeRow({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: SproutRadii.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Thumbnail
                Hero(
                  tag: 'recipe_image_${recipe.id}',
                  flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                            flightDirection == HeroFlightDirection.push
                                ? (1.0 - animation.value) * 16.0
                                : animation.value * 16.0,
                          ),
                          child: toHeroContext.widget,
                        );
                      },
                    );
                  },
                  child: ClipRRect(
                    borderRadius: SproutRadii.borderMd,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: _buildThumbnail(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recipe.matchPercentage > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${recipe.matchPercentage.toInt()}% MATCH',
                            style: SproutTypography.caption(
                              color: SproutColors.sproutGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SproutTypography.h3().copyWith(
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SproutDietBadge(diet: recipe.diet, size: 12),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: SproutColors.secondaryInk,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.totalTimeMins > 0
                                ? '${recipe.totalTimeMins} min'
                                : '20-25 min',
                            style: SproutTypography.small(),
                          ),
                          const SizedBox(width: 6),
                          Text('·', style: SproutTypography.smallBold()),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              recipe.cuisine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SproutTypography.small(),
                            ),
                          ),
                          if (recipe.rating != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              recipe.rating!.toStringAsFixed(1),
                              style: SproutTypography.smallBold(),
                            ),
                          ],
                        ],
                      ),
                      if (recipe.missingIngredients.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: SproutColors.sproutGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Missing: ${recipe.missingIngredients.take(2).join(', ')}${recipe.missingIngredients.length > 2 ? ' +${recipe.missingIngredients.length - 2}' : ''} · Swaps ready',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SproutTypography.caption(
                                  color: SproutColors.secondaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing Favorite or Arrow
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    recipe.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: recipe.isSaved
                        ? SproutColors.tomato
                        : SproutColors.secondaryInk,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return SproutRecipeImage(
      imageUrl: recipe.imageUrl,
      cuisine: recipe.cuisine,
      title: recipe.title,
      width: 80,
      height: 80,
      borderRadius: SproutRadii.borderMd,
    );
  }
}
