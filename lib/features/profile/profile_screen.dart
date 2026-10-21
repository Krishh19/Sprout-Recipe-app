import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_filter_chip.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/components/sprout_recipe_image.dart';
import '../../design/typography.dart';
import '../../models/cook_history_item.dart';
import '../../providers/app_providers.dart';
import '../planner/meal_planner_screen.dart';
import '../scanner/widgets/pantry_staples_sheet.dart';
import '../shopping/shopping_list_screen.dart';



class ProfileScreen extends ConsumerWidget {
  final ValueChanged<int>? onTabSwitch;

  const ProfileScreen({super.key, this.onTabSwitch});

  void _showSheet(BuildContext context, {required String title, required String subtitle, required String imageAsset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: SproutColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: SproutColors.sage.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SproutEmptyState(
                  imageAsset: imageAsset,
                  imageHeight: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: title,
                  subtitle: subtitle,
                  actionLabel: 'Got it',
                  onAction: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCookHistorySheet(BuildContext context, List<CookHistoryItem> history) {
    if (history.isEmpty) {
      _showSheet(
        context,
        title: 'No Cook History Yet',
        subtitle: 'Complete recipes in Cooking Mode to see your accomplishments here!',
        imageAsset: SproutAssets.emptyFinishedCooking,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cook History 🍳', style: SproutTypography.h3()),
                  Text(
                    '${history.length} completed',
                    style: SproutTypography.caption(
                      color: SproutColors.sproutGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = history[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SproutColors.canvas,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          SproutRecipeImage(
                            imageUrl: item.recipeImageUrl,
                            cuisine: 'Indian',
                            title: item.recipeTitle,
                            width: 50,
                            height: 50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.recipeTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SproutTypography.bodyBold(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.cuisine} · ${item.totalTimeMins} min',
                                  style: SproutTypography.small(color: SproutColors.secondaryInk),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_rounded, color: SproutColors.sproutGreen, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPreferencesSheet(BuildContext context, WidgetRef ref) {
    final categories = [
      {
        'title': '🥗 Dietary Pattern',
        'items': ['Vegetarian', 'Vegan', 'Eggitarian', 'Non-veg'],
      },
      {
        'title': '⚡ Cooking Rhythm',
        'items': ['Quick 20-min meals', 'One-pot meals', 'High protein', 'Comfort food'],
      },
      {
        'title': '🍛 Favorite Cuisines',
        'items': ['North Indian', 'South Indian', 'Asian', 'Mediterranean'],
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(preferencesProvider);
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: SproutColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Preferences 🌱', style: SproutTypography.h3()),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categories.map((cat) {
                          final title = cat['title'] as String;
                          final items = cat['items'] as List<String>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: SproutTypography.smallBold(color: SproutColors.secondaryInk)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: items.map((pref) {
                                  final isSel = selected.contains(pref);
                                  return SproutFilterChip(
                                    label: pref,
                                    isSelected: isSel,
                                    onSelected: () {
                                      ref.read(preferencesProvider.notifier).toggle(pref);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCount = ref.watch(savedRecipesProvider).value?.length ?? 0;
    final collectionsCount = ref.watch(collectionsProvider).value?.length ?? 0;
    final cookHistory = ref.watch(cookHistoryProvider).value ?? [];
    final cookedCount = cookHistory.length;
    final preferences = ref.watch(preferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);

    return SproutScaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Artisanal Banner Collage safely inset from top status bar
            SafeArea(
              bottom: false,
              left: true,
              right: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  width: double.infinity,
                decoration: BoxDecoration(
                  color: SproutColors.surface,
                  borderRadius: SproutRadii.card,
                  border: Border.all(
                    color: SproutColors.sage.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SproutColors.primaryInk.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Decorative Banner
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          height: 112,
                          width: double.infinity,
                          child: Image.asset(
                            SproutAssets.bannerCollage,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Soft scrim gradient overlay for contrast and theme transition
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: isDark ? 0.65 : 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Quick Dark / Light mode toggle placed gracefully on top-right of banner
                        Positioned(
                          top: 12,
                          right: 12,
                          child: SproutBouncyTap(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(themeModeProvider.notifier).toggleDarkMode();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SproutColors.surface.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 18,
                                color: isDark
                                    ? SproutColors.butter
                                    : SproutColors.sproutGreen,
                              ),
                            ),
                          ),
                        ),
                        // Sprout Mascot Avatar overlapping the banner bottom
                        Positioned(
                          bottom: -28,
                          left: 20,
                          child: Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: SproutColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? SproutColors.nightAccent
                                    : SproutColors.sproutGreen,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              SproutAssets.mascotWave,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34), // Clearance for overlapping avatar

                    // Name, Bio, and Stats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chef Sprout 👋',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cooking with passion.',
                            style: SproutTypography.body(
                              color: SproutColors.secondaryInk,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 20),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(child: _buildStatItem('Saved', '$savedCount')),
                              Container(
                                height: 28,
                                width: 1,
                                color: SproutColors.sage.withValues(alpha: 0.3),
                              ),
                              Expanded(child: _buildStatItem('Cooked', '$cookedCount')),
                              Container(
                                height: 28,
                                width: 1,
                                color: SproutColors.sage.withValues(alpha: 0.3),
                              ),
                              Expanded(child: _buildStatItem('Collections', '$collectionsCount')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
              const SizedBox(height: 24),

              // Cooking Rhythm Insight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: SproutColors.sproutGreen.withValues(alpha: 0.08),
                  borderRadius: SproutRadii.borderMd,
                  border: Border.all(
                    color: SproutColors.sproutGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: SproutColors.sproutGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cookedCount >= 3
                            ? 'Cooking rhythm: Prefers quick 20-30 min meals · $cookedCount ${cookedCount == 1 ? 'recipe' : 'recipes'} made'
                            : 'Cooking rhythm: Cook at least 3 recipes to build your personal rhythm 🌱',
                        style: SproutTypography.caption(
                          color: SproutColors.primaryInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Preferences Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Diet & Cooking Preferences',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showEditPreferencesSheet(context, ref),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Edit',
                      style: SproutTypography.smallBold(
                        color: isDark ? SproutColors.nightAccent : SproutColors.sproutGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (preferences.isEmpty)
                Text(
                  'No dietary preferences set. Tap Edit to personalize.',
                  style: SproutTypography.body(color: SproutColors.secondaryInk),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preferences.map((p) {
                    return Chip(
                      label: Text(p),
                      backgroundColor: SproutColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: SproutRadii.borderPill,
                        side: BorderSide(
                          color: SproutColors.sage.withValues(alpha: 0.35),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 28),

              // Mockup Card 1: Core Navigation Tabs (matching mockup image)
              _buildGroupedCard(
                isDark: isDark,
                items: [
                  _buildMockupRowItem(
                    icon: Icons.menu_book_outlined,
                    title: 'My Recipes',
                    onTap: () {
                      if (onTabSwitch != null) {
                        onTabSwitch!(3);
                      } else {
                        _showCookHistorySheet(context, cookHistory);
                      }
                    },
                  ),
                  _buildMockupRowItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Shopping List',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                    ),
                  ),
                  _buildMockupRowItem(
                    icon: Icons.speed_outlined,
                    title: 'Nutrition Goals',
                    onTap: () => _showNutritionGoalsSheet(context),
                  ),
                  _buildMockupRowItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Reminders',
                    onTap: () => _showRemindersSheet(context),
                  ),
                  _buildMockupRowItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    showDivider: false,
                    onTap: () => _showSettingsSheet(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Mockup Card 2: Kitchen Management
              _buildGroupedCard(
                isDark: isDark,
                items: [
                  _buildMockupRowItem(
                    icon: Icons.kitchen_rounded,
                    title: 'Kitchen Staples',
                    onTap: () => PantryStaplesSheet.show(context),
                  ),
                  _buildMockupRowItem(
                    icon: Icons.history_rounded,
                    title: 'Cook History',
                    showDivider: false,
                    onTap: () => _showCookHistorySheet(context, cookHistory),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  String _getThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        return 'System Default (${platformDark ? "Dark" : "Light"})';
      case ThemeMode.light:
        return 'Light Mode (Cream & Sage)';
      case ThemeMode.dark:
        return 'Dark Mode (Deep Emerald)';
    }
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentMode = ref.watch(themeModeProvider);
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: SproutColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text('Appearance & Theme', style: SproutTypography.h3()),
                const SizedBox(height: 6),
                Text(
                  'Choose how Sprout looks while you cook and explore recipes.',
                  style: SproutTypography.caption(color: SproutColors.secondaryInk),
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  ctx: ctx,
                  ref: ref,
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  icon: Icons.brightness_auto_rounded,
                  title: 'System Default',
                  subtitle: 'Automatically matches your device dark/light setting',
                ),
                _buildThemeOptionTile(
                  ctx: ctx,
                  ref: ref,
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  icon: Icons.light_mode_rounded,
                  title: 'Light Mode',
                  subtitle: 'Warm artisanal cream canvas with sage green accents',
                ),
                _buildThemeOptionTile(
                  ctx: ctx,
                  ref: ref,
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: 'Deep kitchen emerald night canvas with mint accents',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext ctx,
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentMode == mode;
    return SproutBouncyTap(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.of(ctx).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? SproutColors.accent.withValues(alpha: 0.12)
              : SproutColors.canvas,
          borderRadius: SproutRadii.card,
          border: Border.all(
            color: isSelected
                ? SproutColors.accent
                : SproutColors.sage.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? SproutColors.accent.withValues(alpha: 0.2)
                    : SproutColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? SproutColors.accent : SproutColors.primaryInk,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SproutTypography.body(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: SproutTypography.small(color: SproutColors.secondaryInk),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: SproutColors.accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: SproutTypography.h2().copyWith(
            color: SproutColors.isDarkMode ? Colors.white : SproutColors.sproutGreen,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: SproutTypography.caption(
            color: SproutColors.secondaryInk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard({
    required List<Widget> items,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: isDark ? 0.22 : 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  Widget _buildMockupRowItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: SproutColors.primaryInk.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: subtitle == null
                        ? Text(
                            title,
                            style: SproutTypography.body(fontWeight: FontWeight.w600).copyWith(
                              fontSize: 16,
                              color: SproutColors.primaryInk,
                              letterSpacing: -0.2,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: SproutTypography.body(fontWeight: FontWeight.w600).copyWith(
                                  fontSize: 16,
                                  color: SproutColors.primaryInk,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: SproutTypography.small(color: SproutColors.secondaryInk),
                              ),
                            ],
                          ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: SproutColors.secondaryInk.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.8,
            indent: 56,
            endIndent: 20,
            color: SproutColors.sage.withValues(alpha: 0.14),
          ),
      ],
    );
  }

  void _showRemindersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: SproutColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reminders 🔔', style: SproutTypography.h3()),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay consistent with thoughtful culinary notifications.',
                    style: SproutTypography.caption(color: SproutColors.secondaryInk),
                  ),
                  const SizedBox(height: 18),
                  _buildReminderTile(
                    title: 'Daily Dinner Inspiration',
                    time: '6:30 PM everyday',
                    initialValue: true,
                    icon: Icons.dinner_dining_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildReminderTile(
                    title: 'Weekend Grocery Trip',
                    time: 'Saturday 10:00 AM',
                    initialValue: true,
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildReminderTile(
                    title: 'Cooking Step Timers',
                    time: 'Alerts & sound chimes',
                    initialValue: true,
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SproutColors.sproutGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Done',
                        style: SproutTypography.bodyBold(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderTile({
    required String title,
    required String time,
    required bool initialValue,
    required IconData icon,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initialValue;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SproutColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SproutColors.sage.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: SproutColors.sproutGreen, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SproutTypography.body(fontWeight: FontWeight.w600)),
                    Text(time, style: SproutTypography.small(color: SproutColors.secondaryInk)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeTrackColor: SproutColors.sproutGreen,
                activeThumbColor: Colors.white,
                onChanged: (newVal) {
                  setState(() => value = newVal);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNutritionGoalsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nutrition Goals 🎯', style: SproutTypography.h3()),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Personal daily macro targets based on your dietary pattern.',
                style: SproutTypography.caption(color: SproutColors.secondaryInk),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroGoalCard(
                      label: 'Calories',
                      target: '2,000',
                      unit: 'kcal / day',
                      color: SproutColors.sproutGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMacroGoalCard(
                      label: 'Protein',
                      target: '65g',
                      unit: '15% split',
                      color: SproutColors.butter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroGoalCard(
                      label: 'Carbohydrates',
                      target: '225g',
                      unit: '55% split',
                      color: SproutColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMacroGoalCard(
                      label: 'Healthy Fats',
                      target: '55g',
                      unit: '30% split',
                      color: SproutColors.leaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    'Open 7-Day Meal Planner',
                    style: SproutTypography.bodyBold(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SproutColors.sproutGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MealPlannerScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroGoalCard({
    required String label,
    required String target,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SproutColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: SproutTypography.smallBold(color: SproutColors.secondaryInk)),
            ],
          ),
          const SizedBox(height: 6),
          Text(target, style: SproutTypography.h3().copyWith(fontSize: 20)),
          Text(unit, style: SproutTypography.caption(color: SproutColors.secondaryInk)),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings ⚙️', style: SproutTypography.h3()),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMockupRowItem(
                icon: Icons.contrast_rounded,
                title: 'Appearance & Theme',
                subtitle: _getThemeSubtitle(ref.watch(themeModeProvider)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showThemeModeSheet(context, ref);
                },
              ),
              _buildMockupRowItem(
                icon: Icons.info_outline_rounded,
                title: 'About Sprout',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAboutSproutSheet(context);
                },
              ),
              _buildMockupRowItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                showDivider: false,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showTermsAndConditionsSheet(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSproutSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: SproutColors.sage.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SproutColors.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          SproutAssets.mascotCooking,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sprout · Culinary Companion',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Version 1.0.0 (Production Release)',
                          style: SproutTypography.caption(
                            color: SproutColors.sproutGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'About Sprout',
                  style: SproutTypography.bodyBold(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sprout is your intelligent culinary assistant designed to bring joy, creativity, and ease to home cooking. By combining smart ingredient recognition, AI-powered substitutions, and nutritional science, Sprout turns whatever is in your kitchen into delicious, wholesome meals.',
                  style: SproutTypography.body(color: SproutColors.secondaryInk),
                ),
                const SizedBox(height: 20),
                Text(
                  'Key Features & Technology',
                  style: SproutTypography.bodyBold(),
                ),
                const SizedBox(height: 10),
                _buildAboutFeatureTile(
                  icon: Icons.bolt_rounded,
                  title: 'High-Speed AI Nutrition',
                  description: 'Per-serving calories, macro splits, and dietary insights powered server-side by Groq (Qwen 3.8 27B) and Gemini.',
                ),
                _buildAboutFeatureTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Multimodal Pantry Scanner',
                  description: 'Snap photos of your fridge or countertop to automatically detect fresh ingredients and staples.',
                ),
                _buildAboutFeatureTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Smart Culinary Substitutions',
                  description: 'Missing an ingredient? Get chef-approved swaps and ratio adjustments tailored to each dish.',
                ),
                _buildAboutFeatureTile(
                  icon: Icons.translate_rounded,
                  title: 'Bilingual Hindi & English',
                  description: 'Seamless full-recipe translations while preserving traditional culinary spice terms and techniques.',
                ),
                _buildAboutFeatureTile(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Cloud Security',
                  description: 'Zero hardcoded keys in the app. All AI processing runs through encrypted Supabase Edge Functions.',
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Crafted with 💚 for food lovers everywhere.',
                    style: SproutTypography.small(
                      color: SproutColors.secondaryInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsAndConditionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: SproutColors.sage.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Terms & Conditions 📜', style: SproutTypography.h3()),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: October 2026',
                  style: SproutTypography.caption(color: SproutColors.secondaryInk),
                ),
                const SizedBox(height: 16),
                _buildTermsSection(
                  title: '1. Acceptance of Terms',
                  body: 'By downloading, installing, or using Sprout ("the Application"), you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, please discontinue using the Application.',
                ),
                _buildTermsSection(
                  title: '2. Culinary & Health Disclaimer',
                  body: 'Recipes, nutritional estimates, prep guidelines, and ingredient substitutions provided in Sprout are for general educational and informational purposes only. Nutritional breakdowns are estimated using artificial intelligence and culinary heuristics and should not replace clinical medical advice. Always check food labels for allergen warnings and follow safe cooking temperatures.',
                ),
                _buildTermsSection(
                  title: '3. AI Features & Accuracy',
                  body: 'Sprout uses multimodal vision and language models (via Groq and Google Gemini) to recognize ingredients and translate recipes. While we strive for high accuracy, AI interpretations may occasionally misidentify items. Please verify ingredients before consuming.',
                ),
                _buildTermsSection(
                  title: '4. Privacy & Data Handling',
                  body: 'Sprout values your privacy. Photos scanned for ingredient recognition are processed in real time and are not sold or shared with third-party advertisers. All server requests are encrypted and authenticated via Supabase.',
                ),
                _buildTermsSection(
                  title: '5. Intellectual Property',
                  body: 'All artwork, logos, the Sprout mascot, interface designs, sound effects, and software code are the proprietary intellectual property of Sprout and its creators. Unauthorized reproduction or reverse engineering is prohibited.',
                ),
                _buildTermsSection(
                  title: '6. Limitation of Liability',
                  body: 'Under no circumstances shall Sprout or its developers be held liable for any food preparation accidents, allergic reactions, foodborne illnesses, or kitchen damage resulting from the use of recipes or advice provided by the Application.',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SproutColors.sproutGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SproutColors.sproutGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SproutColors.sproutGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SproutTypography.body(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description, style: SproutTypography.small(color: SproutColors.secondaryInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SproutTypography.body(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            body,
            style: SproutTypography.small(color: SproutColors.secondaryInk),
          ),
        ],
      ),
    );
  }
}
