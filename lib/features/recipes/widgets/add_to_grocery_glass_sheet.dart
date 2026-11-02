import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ingredient_matcher.dart';
import '../../../design/colors.dart';
import '../../../design/glass.dart';
import '../../../design/sprout_haptics.dart';
import '../../../design/sprout_ingredient_formatter.dart';
import '../../../design/sprout_ingredient_scaler.dart';
import '../../../design/typography.dart';
import '../../../models/recipe.dart';
import '../../../providers/app_providers.dart';
import '../../shopping/shopping_list_screen.dart';

/// Frosted Glass "Add to Grocery" Modal Bottom Sheet matching the reference UI.
class AddToGroceryGlassSheet extends ConsumerStatefulWidget {
  final Recipe recipe;
  final int servings;

  const AddToGroceryGlassSheet({
    super.key,
    required this.recipe,
    this.servings = 4,
  });

  static Future<void> show(
    BuildContext context, {
    required Recipe recipe,
    int servings = 4,
  }) {
    return SproutGlassModalSheet.show(
      context: context,
      builder: (_) => AddToGroceryGlassSheet(
        recipe: recipe,
        servings: servings,
      ),
    );
  }

  @override
  ConsumerState<AddToGroceryGlassSheet> createState() =>
      _AddToGroceryGlassSheetState();
}

class _AddToGroceryGlassSheetState
    extends ConsumerState<AddToGroceryGlassSheet> {
  final Set<String> _selectedItems = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSelectedIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initSelectedIngredients() {
    final pantry = ref.read(pantryProvider).value ?? [];
    final scale = widget.servings > 0
        ? widget.servings / (widget.recipe.servings > 0 ? widget.recipe.servings : 1)
        : 1.0;

    for (var rawIng in widget.recipe.ingredients) {
      final scaled = SproutIngredientScaler.scale(rawIng, scale);
      final hasInPantry = pantry.any((p) => IngredientMatcher.isMatch(userItem: p, recipeIngredient: scaled));

      // Select by default if not in pantry
      if (!hasInPantry) {
        _selectedItems.add(scaled);
      }
    }

    // Fallback: If all are in pantry, select all by default so user can still add
    if (_selectedItems.isEmpty) {
      for (var rawIng in widget.recipe.ingredients) {
        _selectedItems.add(SproutIngredientScaler.scale(rawIng, scale));
      }
    }
  }

  Future<void> _exportToGrocery() async {
    if (_selectedItems.isEmpty) return;
    SproutHaptics.medium();

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final count = _selectedItems.length;

    Navigator.of(context).pop();

    await ref.read(shoppingListProvider.notifier).addItems(
          _selectedItems.toList(),
          recipeTitle: widget.recipe.displayTitle,
        );

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF241F1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Added $count ingredients to grocery list! 🛒',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'View List',
          textColor: SproutColors.glassWarmAmber,
          onPressed: () {
            nav.push(
              MaterialPageRoute(
                builder: (_) => const ShoppingListScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider).value ?? [];
    final scale = widget.servings > 0
        ? widget.servings / (widget.recipe.servings > 0 ? widget.recipe.servings : 1)
        : 1.0;

    final allIngredients = widget.recipe.ingredients
        .map((i) => SproutIngredientScaler.scale(i, scale))
        .toList();

    final filtered = _searchQuery.isEmpty
        ? allIngredients
        : allIngredients
            .where((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final toBuy = <String>[];
    final alreadyInPantry = <String>[];

    for (var ing in filtered) {
      final inPantry = pantry.any((p) => IngredientMatcher.isMatch(userItem: p, recipeIngredient: ing));
      if (inPantry) {
        alreadyInPantry.add(ing);
      } else {
        toBuy.add(ing);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar: [X]  |  "Add to Grocery" / Subtitle  |  [🛒]
            Row(
              children: [
                SproutGlassCircleButton(
                  iconData: Icons.close_rounded,
                  size: 40,
                  iconSize: 18,
                  tooltip: 'Close',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Grocery',
                        style: SproutTypography.h3(color: Colors.white)
                            .copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.recipe.displayTitle} · ${widget.recipe.ingredients.length} unique ingredients',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SproutGlassCircleButton(
                  iconData: Icons.shopping_cart_outlined,
                  size: 40,
                  iconSize: 18,
                  tooltip: 'Add to Cart',
                  onTap: _exportToGrocery,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable Ingredients Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: "To buy · {count}"
                    Row(
                      children: [
                        Text(
                          'To buy · ${toBuy.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // To Buy Items
                    ...toBuy.map((item) => _buildIngredientRow(item)),

                    const SizedBox(height: 12),
                    // Footnote
                    Text(
                      'Selected by default because these ingredients are not in your pantry or active grocery list.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: "Already on your list / in pantry · {count}"
                    if (alreadyInPantry.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Already in your pantry · ${alreadyInPantry.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...alreadyInPantry
                          .map((item) => _buildIngredientRow(item)),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Search Bar ("🔍 Search ingredients")
            SproutGlassSearchBar(
              controller: _searchController,
              hintText: 'Search ingredients',
              onChanged: (q) => setState(() => _searchQuery = q),
              onClear: () => setState(() => _searchQuery = ''),
            ),
            const SizedBox(height: 14),

            // Primary Add Selected Button (Solid warm cream button)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedItems.isNotEmpty
                      ? SproutColors.glassCreamPill
                      : Colors.white24,
                  foregroundColor: _selectedItems.isNotEmpty
                      ? SproutColors.glassCreamPillText
                      : Colors.white38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _selectedItems.isNotEmpty ? _exportToGrocery : null,
                child: Text(
                  _selectedItems.isNotEmpty
                      ? 'Add ${_selectedItems.length} Ingredients to Grocery'
                      : 'Select ingredients to add',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientRow(String rawIng) {
    final parsed = SproutIngredientFormatter.parseIngredient(rawIng);
    final isSelected = _selectedItems.contains(rawIng);

    return InkWell(
      onTap: () {
        SproutHaptics.selection();
        setState(() {
          if (isSelected) {
            _selectedItems.remove(rawIng);
          } else {
            _selectedItems.add(rawIng);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0x14FFFFFF),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            // Item Leading Icon/Thumbnail Capsule
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🥗', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),

            // Ingredient Name & Quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parsed.primaryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (parsed.displayQuantity.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      parsed.displayQuantity,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Checkbox Pill: white circle with checkmark when selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF1B1917),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

