import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_recipe_row.dart';
import '../../../design/typography.dart';

import '../../../models/recipe.dart';
import '../../../providers/app_providers.dart';

class RecipePickerSheet extends ConsumerStatefulWidget {
  final String title;

  const RecipePickerSheet({
    super.key,
    this.title = 'Select a Recipe',
  });

  static Future<Recipe?> show(BuildContext context, {String title = 'Select a Recipe'}) {
    return showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipePickerSheet(title: title),
    );
  }

  @override
  ConsumerState<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<RecipePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(recipeRepositoryProvider);
    final results = await repo.searchRecipes(query: query.trim(), pageSize: 15);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedRecipes = ref.watch(savedRecipesProvider).value ?? [];

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SproutColors.sage.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: SproutTypography.h3()),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search 5,900+ recipes...',
                hintStyle: SproutTypography.body(
                  color: SproutColors.secondaryInk.withValues(alpha: 0.6),
                ).copyWith(fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: SproutColors.secondaryInk,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: SproutColors.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: SproutColors.sage.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: SproutColors.sage.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: SproutColors.sproutGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content List
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: SproutColors.sproutGreen,
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'No recipes found for "${_searchController.text}"',
                                style: SproutTypography.body(
                                  color: SproutColors.secondaryInk,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (ctx, idx) {
                                final recipe = _searchResults[idx];
                                return SproutRecipeRow(
                                  recipe: recipe,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).pop(recipe);
                                  },
                                );
                              },
                            )
                      : ListView(
                          children: [
                            if (savedRecipes.isNotEmpty) ...[
                              Text(
                                'From Your Favorites (${savedRecipes.length})',
                                style: SproutTypography.smallBold(
                                  color: SproutColors.secondaryInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...savedRecipes.map((recipe) => SproutRecipeRow(
                                    recipe: recipe,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.of(context).pop(recipe);
                                    },
                                  )),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              'Type in the search bar above to search any recipe.',
                              textAlign: TextAlign.center,
                              style: SproutTypography.caption(
                                color: SproutColors.secondaryInk,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
