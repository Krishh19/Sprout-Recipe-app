import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_recipe_row.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';
import '../../models/collection.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../recipes/recipe_detail_screen.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final RecipeCollection collection;
  final VoidCallback? onExploreTap;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    this.onExploreTap,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    setState(() {
      _recipesFuture = ref
          .read(savedRepositoryProvider)
          .fetchRecipesForCollection(widget.collection.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SproutScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: SproutColors.primaryInk,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.collection.name,
                          style: SproutTypography.h2().copyWith(fontSize: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.collection.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.collection.description,
                            style: SproutTypography.small(
                              color: SproutColors.secondaryInk,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0x15214B38),
            ),

            // Content Body
            Expanded(
              child: FutureBuilder<List<Recipe>>(
                future: _recipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SproutColors.sproutGreen,
                        ),
                      ),
                    );
                  }

                  final recipes = snapshot.data ?? [];

                  if (recipes.isEmpty) {
                    return Center(
                      child: SproutEmptyState(
                        imageAsset: SproutAssets.emptyCollections,
                        title: 'No recipes in ${widget.collection.name}',
                        subtitle:
                            'Save your favorite recipes here to easily find them when you\'re ready to cook.',
                        actionLabel: 'Explore Recipes',
                        onAction: () {
                          Navigator.of(context).pop();
                          widget.onExploreTap?.call();
                        },
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return SproutRecipeRow(
                        recipe: recipe,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                        onFavoriteToggle: () async {
                          await ref
                              .read(savedRecipesProvider.notifier)
                              .toggleFavorite(recipe);
                          _loadRecipes();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
