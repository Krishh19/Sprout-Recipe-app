import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/components/sprout_ingredient_chip.dart';
import '../../../design/radii.dart';
import '../../../design/typography.dart';

class IngredientListCard extends StatelessWidget {
  final List<String> ingredients;
  final ValueChanged<String> onRemoveIngredient;
  final VoidCallback onAddTap;
  final VoidCallback? onClearAll;

  const IngredientListCard({
    super.key,
    required this.ingredients,
    required this.onRemoveIngredient,
    required this.onAddTap,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: "Your Ingredients" + Count Badge + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Your Ingredients',
                        overflow: TextOverflow.ellipsis,
                        style: SproutTypography.h3(color: SproutColors.primaryInk).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF143818),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${ingredients.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ingredients.isNotEmpty && onClearAll != null) ...[
                    SproutBouncyTap(
                      onTap: onClearAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Clear all',
                          style: SproutTypography.caption(
                            color: SproutColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // "+ Add Item" Button
                  SproutBouncyTap(
                    onTap: onAddTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: SproutColors.canvas,
                        borderRadius: SproutRadii.borderPill,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xFF143818),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Item',
                            style: SproutTypography.smallBold(
                              color: const Color(0xFF143818),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Chips Wrap or Empty Prompt
          if (ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Center(
                child: Text(
                  'No ingredients added yet 🌱\nTap a quick add above or snap a photo of your fridge.',
                  textAlign: TextAlign.center,
                  style: SproutTypography.body(
                    color: SproutColors.secondaryInk,
                  ).copyWith(height: 1.45),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ingredients.map((item) {
                return SproutIngredientChip(
                  key: ValueKey(item),
                  label: item,
                  onDeleted: () => onRemoveIngredient(item),
                );
              }).toList(),
            ),

          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Bottom-Right Handwritten Callout: "Good choices! ♡"
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  'Good choices! ♡',
                  style: SproutTypography.handwritten(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3F6B45),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
