import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_blur_header.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_button.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_recipe_row.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_shimmer.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';
import '../../providers/app_providers.dart';
import '../recipes/recipe_detail_screen.dart';
import 'collection_detail_screen.dart';

class SavedScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreTap;

  const SavedScreen({super.key, this.onExploreTap});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SproutColors.surface,
        shape: RoundedRectangleBorder(borderRadius: SproutRadii.card),
        title: Text('New Collection', style: SproutTypography.h3()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Collection Name (e.g. Sunday Brunch)',
                  hintStyle: SproutTypography.body(color: SproutColors.muted),
                  filled: true,
                  fillColor: SproutColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: SproutRadii.borderMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: SproutTypography.body(color: SproutColors.muted),
                  filled: true,
                  fillColor: SproutColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: SproutRadii.borderMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: SproutTypography.body()),
          ),
          SproutButton(
            label: 'Create',
            height: 42,
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(collectionsProvider.notifier).addCollection(
                      name,
                      descController.text.trim(),
                    );
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      descController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final savedAsync = ref.watch(savedRecipesProvider);
    final collectionsAsync = ref.watch(collectionsProvider);

    return SproutScaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title & Action
          SafeArea(
            bottom: false,
            left: true,
            right: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Recipes',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                      letterSpacing: -0.4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                    color: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
                    tooltip: 'New Collection',
                    onPressed: _showCreateCollectionDialog,
                  ),
                ],
              ),
            ),
          ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(3),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
                  width: 1.0,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF244834) : SproutColors.forestGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
                          .withValues(alpha: isDark ? 0.28 : 0.20),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                labelStyle: SproutTypography.smallBold(),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(height: 38, text: 'Favorites'),
                  Tab(height: 38, text: 'Collections'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Body with progressive scroll blur & shadow
            Expanded(
              child: SproutScrollShadowWrapper(
                child: TabBarView(
                  controller: _tabController,
                children: [
                  // Favorites Tab
                  savedAsync.when(
                    data: (recipes) => recipes.isEmpty
                        ? SproutEmptyState(
                            imageAsset: SproutAssets.emptyFavourite,
                            title: 'No saved recipes yet',
                            subtitle:
                                'Tap the heart icon on any recipe to save it to your cookbook.',
                            actionLabel: 'Explore Recipes',
                            onAction: widget.onExploreTap,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];
                              return Dismissible(
                                key: ValueKey('saved_${recipe.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: SproutColors.tomato,
                                    borderRadius: SproutRadii.card,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Remove',
                                        style: SproutTypography.caption(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.favorite_border_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                                onDismissed: (direction) {
                                  HapticFeedback.mediumImpact();
                                  final removedRecipe = recipe;
                                  ref
                                      .read(savedRecipesProvider.notifier)
                                      .toggleFavorite(removedRecipe);
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Removed "${removedRecipe.title}" from saved',
                                      ),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        textColor: SproutColors.sproutGreen,
                                        onPressed: () {
                                          ref
                                              .read(savedRecipesProvider.notifier)
                                              .toggleFavorite(removedRecipe);
                                        },
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: SproutRecipeRow(
                                  recipe: recipe,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            RecipeDetailScreen(recipe: recipe),
                                      ),
                                    );
                                  },
                                  onFavoriteToggle: () {
                                    ref
                                        .read(savedRecipesProvider.notifier)
                                        .toggleFavorite(recipe);
                                  },
                                ),
                              );
                            },
                          ),
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                      itemCount: 5,
                      itemBuilder: (context, index) => const SproutRecipeRowSkeleton(),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  // Collections Tab
                  collectionsAsync.when(
                    data: (colls) => colls.isEmpty
                        ? SproutEmptyState(
                            imageAsset: SproutAssets.emptyCollections,
                            title: 'No collections yet',
                            subtitle:
                                'Create themed collections to organize your recipes.',
                            actionLabel: 'Create Collection',
                            onAction: _showCreateCollectionDialog,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                            itemCount: colls.length,
                            itemBuilder: (context, index) {
                              final coll = colls[index];
                              return SproutBouncyTap(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CollectionDetailScreen(
                                        collection: coll,
                                        onExploreTap: widget.onExploreTap,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: SproutColors.surface,
                                    borderRadius: SproutRadii.card,
                                    border: Border.all(
                                      color: SproutColors.sage.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: SproutColors.sproutGreen
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.bookmark_rounded,
                                          color: SproutColors.sproutGreen,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              coll.name,
                                              style: SproutTypography.h3()
                                                  .copyWith(fontSize: 17),
                                            ),
                                            if (coll.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                coll.description,
                                                style: SproutTypography.small(
                                                  color: SproutColors.secondaryInk,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: SproutColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                      itemCount: 4,
                      itemBuilder: (context, index) => const SproutRecipeRowSkeleton(),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
