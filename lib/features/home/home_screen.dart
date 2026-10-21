import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tutorial/tutorial_manager.dart';
import '../../core/tutorial/tutorial_steps.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_hero_card.dart';
import '../../design/components/sprout_recipe_card.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_resume_cook_card.dart';
import '../../design/components/sprout_search_bar.dart';
import '../../design/components/sprout_shimmer.dart';
import '../../design/sprout_assets.dart';
import '../../design/sprout_haptics.dart';
import '../../design/typography.dart';
import '../../models/cook_history_item.dart';
import '../../providers/app_providers.dart';
import '../cooking/cooking_screen.dart';
import '../planner/meal_planner_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import 'widgets/sprout_weekly_planner_card.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final trendingAsync = ref.watch(trendingRecipesProvider);
    final quickAsync = ref.watch(quickRecipesProvider);
    final cookHistory = ref.watch(cookHistoryProvider).value ?? [];

    final topPadding = MediaQuery.paddingOf(context).top;

    return SproutScaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: SproutColors.forestGreen,
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
              // ---------------------------------------------------------------
              // Reference 1: Large Sage-Green Header with Softly Rounded Bottom
              // ---------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3528) : SproutColors.sage,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  left: true,
                  right: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting, Serif Heading & Mascot Avatar Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: SproutTypography.body(
                                      color: isDark
                                          ? SproutColors.nightAccent
                                          : SproutColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ).copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'What are we cooking today?',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? SproutColors.nightPrimaryInk
                                          : SproutColors.forestGreen,
                                      height: 1.2,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Sprout Mascot waving in circular soft ivory badge
                            Container(
                              width: 58,
                              height: 58,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SproutColors.nightSurface
                                    : SproutColors.softIvory,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: isDark ? 0.25 : 0.70,
                                  ),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
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
                        const SizedBox(height: 18),

                        // Search Trigger Bar embedded inside Sage Header
                        SproutShowcase(
                          step: MainTourSteps.search,
                          child: SproutSearchBar(
                            readOnly: true,
                            hintText: 'Search recipes, ingredients...',
                            onTap: () {
                              widget.onExploreTriggered?.call();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------------------------
              // Reference 1: Side-by-Side Dual Feature Cards
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Card: Scan your ingredients
                      Expanded(
                        child: SproutShowcase(
                          step: MainTourSteps.scanner,
                          child: SproutBouncyTap(
                            onTap: () => widget.onScanTriggered?.call(),
                            child: Semantics(
                              button: true,
                              label: 'Scan your ingredients',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? SproutColors.nightElevatedSurface
                                      : SproutColors.softIvory,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF284031)
                                        : SproutColors.subtleBorder,
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.22 : 0.04,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Illustrated Fresh Vegetables Header with Camera Badge
                                      SizedBox(
                                        height: 78,
                                        width: double.infinity,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(
                                              SproutAssets.scannerFreshBackdrop,
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.55),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 10, 10, 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Scan your ingredients',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.fraunces(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? SproutColors
                                                          .nightPrimaryInk
                                                      : SproutColors
                                                          .textPrimary,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 16,
                                              color: isDark
                                                  ? SproutColors
                                                      .nightSecondaryInk
                                                  : SproutColors
                                                      .textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Card: Weekly Planner Empty State
                      Expanded(
                        child: SproutWeeklyPlannerCard(
                          onCustomTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MealPlannerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Resume in-progress cooking session (if active)
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

              // ---------------------------------------------------------------
              // Reference 1: Promotional Hero Banner
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SproutHeroCard(
                  onTap: () {
                    widget.onExploreTriggered?.call();
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------------
              // Reference 1: Recent Cooks Section
              // ---------------------------------------------------------------
              _buildRecentCooks(context, cookHistory),

              // ---------------------------------------------------------------
              // Additional Content: You Can Make Now
              // ---------------------------------------------------------------
              Builder(
                builder: (context) {
                  final scannerState = ref.watch(scannerProvider);
                  if (scannerState.matchedRecipes.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SproutShowcase(
                        step: MainTourSteps.pantry,
                        child: _buildSectionHeader(
                          title: 'You Can Make Now 🍳',
                          subtitle:
                              '${scannerState.detectedIngredients.length} ingredients ready in your kitchen',
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
                      )
                          .animate()
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),

              // ---------------------------------------------------------------
              // Section: Trending Recipes
              // ---------------------------------------------------------------
              _buildSectionHeader(
                title: 'Trending Recipes',
                subtitle: 'Popular picks from home chefs',
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
                  ),
                  loading: () => SizedBox(
                    height: 275,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: 3,
                      itemBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SproutRecipeCardSkeleton(),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 30),

              // ---------------------------------------------------------------
              // Section: Quick & Easy (under 20 mins)
              // ---------------------------------------------------------------
              _buildSectionHeader(
                title: 'Quick & Easy',
                subtitle: 'Ready in 20 minutes or less',
                onSeeAll: () => widget.onExploreTriggered?.call(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 275,
                child: quickAsync.when(
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
                  ),
                  loading: () => SizedBox(
                    height: 275,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: 3,
                      itemBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SproutRecipeCardSkeleton(),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

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
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SproutTypography.small(
                    color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                  ),
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
                  color: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentCooks(BuildContext context, List<CookHistoryItem> history) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Cooks',
                style: SproutTypography.editorialH2(),
              ),
              const SizedBox(height: 2),
              Text(
                'Dishes you made with Sprout',
                style: SproutTypography.small(
                  color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (history.isNotEmpty)
          SizedBox(
            height: 104,
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
                    color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fraunces(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.cuisine} • ${item.totalTimeMins}m',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SproutTypography.caption(
                                color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          // Friendly gentle placeholder if user hasn't cooked yet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF223629)
                          : SproutColors.paleSage.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        SproutAssets.cookingPot,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No dishes cooked yet',
                          style: GoogleFonts.fraunces(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Start cooking any recipe to see your delicious history here!',
                          style: SproutTypography.caption(
                            color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}
