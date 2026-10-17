import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/components/sprout_empty_state.dart';
import '../../../design/components/sprout_scaffold.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

/// Data model representing an empty state preset across the Sprout application.
class EmptyStatePreset {
  final String id;
  final String screenName;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final String? imageAsset;
  final IconData icon;
  final double imageHeight;

  const EmptyStatePreset({
    required this.id,
    required this.screenName,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.imageAsset,
    this.icon = Icons.eco_rounded,
    this.imageHeight = 130.0,
  });
}

/// Interactive testing screen for verifying all empty states used across the app.
class EmptyStatesGalleryScreen extends StatefulWidget {
  const EmptyStatesGalleryScreen({super.key});

  @override
  State<EmptyStatesGalleryScreen> createState() => _EmptyStatesGalleryScreenState();
}

class _EmptyStatesGalleryScreenState extends State<EmptyStatesGalleryScreen> {
  int _selectedPresetIndex = 0;
  bool _showAllCards = false;

  static const List<EmptyStatePreset> _presets = [
    EmptyStatePreset(
      id: 'saved_recipes',
      screenName: 'Saved Recipes (SavedScreen)',
      title: 'No saved recipes yet',
      subtitle: 'Tap the heart icon on any recipe to save it to your cookbook.',
      actionLabel: 'Explore Recipes',
      imageAsset: SproutAssets.emptyFavourite,
      imageHeight: 140,
    ),
    EmptyStatePreset(
      id: 'collections',
      screenName: 'Collections (SavedScreen)',
      title: 'No collections yet',
      subtitle: 'Create themed collections to organize your recipes.',
      actionLabel: 'Create Collection',
      imageAsset: SproutAssets.emptyCollections,
      imageHeight: 140,
    ),
    EmptyStatePreset(
      id: 'collection_detail',
      screenName: 'Collection Detail (CollectionDetailScreen)',
      title: 'No recipes in Summer Quick Bites',
      subtitle: 'Save your favorite recipes here to easily find them when you\'re ready to cook.',
      actionLabel: 'Explore Recipes',
      imageAsset: SproutAssets.emptyCollections,
      imageHeight: 130,
    ),
    EmptyStatePreset(
      id: 'search_empty',
      screenName: 'Search (SearchScreen)',
      title: 'No recipes found',
      subtitle: 'Try searching for something else or clearing your filters.',
      actionLabel: 'Reset Search',
      imageAsset: SproutAssets.emptySearch,
      imageHeight: 140,
    ),
    EmptyStatePreset(
      id: 'grocery_list',
      screenName: 'Grocery List (ShoppingListScreen)',
      title: 'Grocery List Empty',
      subtitle: 'Tap "Add to Shopping List" on recipe cards to organize your grocery run.',
      actionLabel: 'Browse Recipes',
      imageAsset: SproutAssets.emptyShopping,
      imageHeight: 130,
    ),
    EmptyStatePreset(
      id: 'cook_history',
      screenName: 'Cook History (ProfileScreen)',
      title: 'No Cook History Yet',
      subtitle: 'Complete recipes in Cooking Mode to see your accomplishments here!',
      actionLabel: 'Got it',
      imageAsset: SproutAssets.emptyFinishedCooking,
      imageHeight: 110,
    ),
    EmptyStatePreset(
      id: 'notifications',
      screenName: 'Notifications / Alerts',
      title: 'No new notifications',
      subtitle: 'You are completely caught up! We will notify you when new seasonal recipes arrive.',
      actionLabel: 'Back to Kitchen',
      imageAsset: SproutAssets.emptyNotifications,
      imageHeight: 130,
    ),
    EmptyStatePreset(
      id: 'scanner_no_match',
      screenName: 'Scanner & Pantry Matcher (ScannerScreen)',
      title: 'No recipes found',
      subtitle: 'Try adding more ingredients like onion, tomato, or garlic.',
      actionLabel: 'Add More Ingredients',
      icon: Icons.kitchen_rounded,
      imageHeight: 100,
    ),
  ];

  void _triggerAction(String actionLabel) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SproutColors.primaryInk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: SproutRadii.borderMd),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: SproutColors.sproutGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Action tapped: "$actionLabel" (Test Passed ✅)',
                style: SproutTypography.caption(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _presets[_selectedPresetIndex];

    return SproutScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  SproutBouncyTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: SproutColors.primaryInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Empty States Gallery', style: SproutTypography.h3()),
                        Text(
                          '${_presets.length} app empty states for testing',
                          style: SproutTypography.caption(color: SproutColors.secondaryInk),
                        ),
                      ],
                    ),
                  ),
                  SproutBouncyTap(
                    onTap: () {
                      setState(() {
                        _showAllCards = !_showAllCards;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showAllCards
                            ? SproutColors.sproutGreen.withValues(alpha: 0.15)
                            : SproutColors.surface,
                        borderRadius: SproutRadii.borderPill,
                        border: Border.all(
                          color: _showAllCards
                              ? SproutColors.sproutGreen
                              : SproutColors.sage.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showAllCards ? Icons.view_agenda_rounded : Icons.view_carousel_rounded,
                            size: 16,
                            color: _showAllCards ? SproutColors.sproutGreen : SproutColors.primaryInk,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showAllCards ? 'List View' : 'Single View',
                            style: SproutTypography.caption(
                              color: _showAllCards ? SproutColors.sproutGreen : SproutColors.primaryInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_showAllCards) ...[
              // Preset Chips Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(_presets.length, (index) {
                    final preset = _presets[index];
                    final isSelected = index == _selectedPresetIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SproutBouncyTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedPresetIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? SproutColors.sproutGreen : SproutColors.surface,
                            borderRadius: SproutRadii.borderPill,
                            border: Border.all(
                              color: isSelected
                                  ? SproutColors.sproutGreen
                                  : SproutColors.sage.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: SproutColors.sproutGreen.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            preset.id.replaceAll('_', ' ').toUpperCase(),
                            style: SproutTypography.caption(
                              color: isSelected ? Colors.white : SproutColors.primaryInk,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Single Interactive Preview Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Screen origin chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: SproutColors.sproutGreen.withValues(alpha: 0.1),
                          borderRadius: SproutRadii.borderPill,
                          border: Border.all(
                            color: SproutColors.sproutGreen.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: SproutColors.sproutGreen),
                            const SizedBox(width: 6),
                            Text(
                              current.screenName,
                              style: SproutTypography.caption(
                                color: SproutColors.sproutGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Live Preview Container
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: SproutColors.surface,
                          borderRadius: SproutRadii.card,
                          border: Border.all(
                            color: SproutColors.sage.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SproutEmptyState(
                          title: current.title,
                          subtitle: current.subtitle,
                          actionLabel: current.actionLabel,
                          imageAsset: current.imageAsset,
                          icon: current.icon,
                          imageHeight: current.imageHeight,
                          onAction: current.actionLabel != null
                              ? () => _triggerAction(current.actionLabel!)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Technical Specs Inspector Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SproutColors.surface,
                          borderRadius: SproutRadii.borderMd,
                          border: Border.all(
                            color: SproutColors.sage.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Component Inspector', style: SproutTypography.smallBold()),
                            const SizedBox(height: 10),
                            _buildSpecRow('Target Screen', current.screenName),
                            _buildSpecRow('Visual Type', current.imageAsset != null ? 'Asset Image' : 'Icon Vector'),
                            if (current.imageAsset != null)
                              _buildSpecRow('Asset Path', current.imageAsset!),
                            if (current.imageAsset == null)
                              _buildSpecRow('Icon Data', current.icon.toString()),
                            _buildSpecRow('Action Button', current.actionLabel ?? 'None (Informational)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Scroll All Showcase View
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _presets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        borderRadius: SproutRadii.card,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: SproutColors.sproutGreen.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.layers_outlined, size: 16, color: SproutColors.sproutGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    preset.screenName,
                                    style: SproutTypography.caption(
                                      color: SproutColors.sproutGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: SproutTypography.caption(
                                      color: SproutColors.primaryInk,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SproutEmptyState(
                            title: preset.title,
                            subtitle: preset.subtitle,
                            actionLabel: preset.actionLabel,
                            imageAsset: preset.imageAsset,
                            icon: preset.icon,
                            imageHeight: preset.imageHeight,
                            onAction: preset.actionLabel != null
                                ? () => _triggerAction(preset.actionLabel!)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: SproutTypography.caption(
                color: SproutColors.secondaryInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SproutTypography.caption(
                color: SproutColors.primaryInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
