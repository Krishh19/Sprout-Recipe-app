import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/tutorial/tutorial_manager.dart';
import '../../core/tutorial/tutorial_steps.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_hero_card.dart';
import '../../design/components/sprout_metallic_text.dart';
import '../../design/components/sprout_recipe_card.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_resume_cook_card.dart';
import '../../design/components/sprout_search_bar.dart';
import '../../design/components/sprout_shimmer.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/sprout_haptics.dart';
import '../../design/typography.dart';
import '../../models/cook_history_item.dart';
import '../../providers/app_providers.dart';
import '../cooking/cooking_screen.dart';
import '../planner/meal_planner_screen.dart';
import '../recipes/recipe_detail_screen.dart';


class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onSearchTriggered;
  final VoidCallback? onExploreTriggered;
  final VoidCallback? onScanTriggered;

  const HomeScreen({
    super.key,
    this.onSearchTriggered,
    this.onExploreTriggered,
    this.onScanTriggered,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tutorialManagerProvider).startMainTour(context);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingRecipesProvider);
    final quickAsync = ref.watch(quickRecipesProvider);
    final cookHistory = ref.watch(cookHistoryProvider).value ?? [];

    final topPadding = MediaQuery.paddingOf(context).top;

    return SproutScaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: SproutColors.sproutGreen,
        backgroundColor: SproutColors.surface,
        edgeOffset: topPadding,
        onRefresh: () async {
          ref.invalidate(trendingRecipesProvider);
          ref.invalidate(quickRecipesProvider);
          await Future.wait([
            ref.read(trendingRecipesProvider.future),
            ref.read(quickRecipesProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          // Bottom inset accounts for the translucent nav bar so the
          // final section is never trapped underneath it.
          padding: const EdgeInsets.only(bottom: 124),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Greeting safely inset from the top status bar / camera cutout
              SafeArea(
                bottom: false,
                left: true,
                right: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: SproutTypography.body(
                                color: SproutColors.secondaryInk,
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            SproutMetallicHeading(
                              'What are we cooking today?',
                              style: SproutTypography.h2().copyWith(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sprout Mascot waving badge
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: SproutColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SproutColors.sage.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SproutColors.primaryInk.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          SproutAssets.mascotWave,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Trigger Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SproutShowcase(
                  step: MainTourSteps.search,
                  child: SproutSearchBar(
                    readOnly: true,
                    onTap: () {
                      widget.onExploreTriggered?.call();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Scan Your Kitchen Action Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SproutShowcase(
                  step: MainTourSteps.scanner,
                  child: SproutBouncyTap(
                    onTap: () => widget.onScanTriggered?.call(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        borderRadius: SproutRadii.card,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.20),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SproutColors.primaryInk.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: SproutColors.sproutGreen.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              SproutAssets.emptySearch,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan your ingredients',
                                  style: SproutTypography.bodyBold().copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Show Sprout what's in your kitchen to cook now",
                                  style: SproutTypography.caption(color: SproutColors.secondaryInk),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: SproutColors.secondaryInk.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Today's Meal Plan Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Builder(
                  builder: (context) {
                    final mealPlan = ref.watch(mealPlanProvider).value ?? [];
                    final todayWeekday = DateTime.now().weekday;
                    final todayMeals =
                        mealPlan.where((m) => m.dayOfWeek == todayWeekday).toList();

                    return SproutBouncyTap(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MealPlannerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.surface,
                          borderRadius: SproutRadii.card,
                          border: Border.all(
                            color: SproutColors.sage.withValues(alpha: 0.20),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SproutColors.primaryInk.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🗓️', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayMeals.isNotEmpty
                                        ? "Today's Plan (${todayMeals.length} planned)"
                                        : "Weekly Meal Planner",
                                    style: SproutTypography.bodyBold().copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    todayMeals.isNotEmpty
                                        ? todayMeals
                                            .map((m) =>
                                                '${m.mealType.emoji} ${m.recipe.title}')
                                            .join(' · ')
                                        : "Schedule your week & generate groceries",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SproutTypography.caption(
                                      color: SproutColors.secondaryInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: SproutColors.accent,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),


              // Resume in-progress cooking session
              Builder(
                builder: (context) {
                  final session = ref.watch(cookSessionProvider).value;
                  if (session == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SproutResumeCookCard(
                      session: session,
                      onResume: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CookingScreen(recipe: session.recipe),
                          ),
                        );
                      },
                      onDismiss: () {
                        ref.read(cookSessionProvider.notifier).clear();
                      },
                    ),
                  );
                },
              ),


              // Hero Editorial Module
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SproutHeroCard(
                  onTap: () {
                    widget.onExploreTriggered?.call();
                  },
                ),
              ),
              const SizedBox(height: 32),

              // You Can Make Now (Pantry & Scanner Matches)
              Builder(
                builder: (context) {
                  final scannerState = ref.watch(scannerProvider);
                  if (scannerState.matchedRecipes.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SproutShowcase(
                        step: MainTourSteps.pantry,
                        child: _buildSectionHeader(
                          title: 'You Can Make Now 🍳',
                          subtitle: '${scannerState.detectedIngredients.length} ingredients ready in your kitchen',
                          onSeeAll: () => widget.onScanTriggered?.call(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 275,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: scannerState.matchedRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = scannerState.matchedRecipes[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SproutRecipeCard(
                                recipe: recipe,
                                heroTagPrefix: 'recipe_image_scan',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                                    ),
                                  );
                                },
                                onFavoriteToggle: () {
                                  ref.read(savedRecipesProvider.notifier).toggleFavorite(recipe);
                                },
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),

              // Recent Cooks Feed
              _buildRecentCooks(context, cookHistory),

              // Section 1: For You / Trending Recipes
              _buildSectionHeader(
                title: 'Trending Recipes',
                subtitle: 'Popular picks',
                onSeeAll: () => widget.onExploreTriggered?.call(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 275,
                child: trendingAsync.when(
                  data: (recipes) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: SproutRecipeCard(
                          recipe: recipe,
                          heroTagPrefix: 'recipe_image_trending',
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
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
                  loading: () => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: SproutRecipeCardSkeleton(),
                    ),
                  ),
                  error: (e, _) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 32),

              // Section 2: Cook in 30 min (Deduplicated against Trending)
              _buildSectionHeader(
                title: 'Cook in 30 min ⏱️',
                subtitle: 'Easy weekday meals',
                onSeeAll: () => widget.onExploreTriggered?.call(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 275,
                child: quickAsync.when(
                  data: (recipes) {
                    final trending = trendingAsync.value ?? [];
                    final trendingIds = trending.map((r) => r.id).toSet();
                    final deduplicated = recipes.where((r) => !trendingIds.contains(r.id)).toList();
                    final displayList = deduplicated.isNotEmpty ? deduplicated : recipes;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final recipe = displayList[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: SproutRecipeCard(
                            recipe: recipe,
                            heroTagPrefix: 'recipe_image_quick',
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
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
                  },
                  loading: () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: 4,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SproutRecipeCardSkeleton(),
                  ),
                ),
                error: (e, _) => const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SproutMetallicHeading(title, style: SproutTypography.h3()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SproutTypography.small(color: SproutColors.secondaryInk),
                ),
              ],
            ),
          ),
          if (onSeeAll != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                SproutHaptics.selection();
                onSeeAll();
              },
              child: Text(
                'See all →',
                style: SproutTypography.smallBold(
                  color: SproutColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentCooks(BuildContext context, List<CookHistoryItem> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SproutMetallicHeading('Recent Cooks 🍳', style: SproutTypography.h3()),
              const SizedBox(height: 2),
              Text(
                'Dishes you successfully made with Sprout',
                style: SproutTypography.small(color: SproutColors.secondaryInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final item = history[idx];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SproutColors.surface,
                  borderRadius: SproutRadii.card,
                  border: Border.all(
                    color: SproutColors.sage.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: item.recipeImageUrl != null && item.recipeImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.recipeImageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Image.asset(
                                  SproutAssets.imageNotFound,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                SproutAssets.imageNotFound,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.recipeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SproutTypography.smallBold(),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 13, color: SproutColors.sproutGreen),
                              const SizedBox(width: 3),
                              Text(
                                '${item.totalTimeMins}m · Cooked',
                                style: SproutTypography.caption(color: SproutColors.sproutGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
