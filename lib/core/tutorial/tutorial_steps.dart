import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import 'sprout_coach_mark.dart';
import 'tutorial_manager.dart';
import 'tutorial_targets.dart';

/// Data model representing an individual step in the guided tour.
class TutorialStepDefinition {
  final GlobalKey key;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final ShapeBorder shapeBorder;
  final String? imageAsset;

  const TutorialStepDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.shapeBorder,
    this.imageAsset,
  });
}

/// Centralized copy and definitions for the main 5-step Sprout tour.
class MainTourSteps {
  MainTourSteps._();

  static const int totalCount = 5;

  static List<TutorialStepDefinition> getSteps() {
    final targets = TutorialTargets.instance;

    return [
      TutorialStepDefinition(
        key: targets.scannerKey,
        title: 'Scan your food 📸',
        description:
            "Tap the magic lens to photograph kitchen ingredients or barcodes. Sprout immediately tells you what you can make.",
        stepIndex: 0,
        totalSteps: totalCount,
        // Step 1 targets the "Scan your ingredients" card — rounded rect,
        // matching the card's own corner radius.
        shapeBorder: const RoundedRectangleBorder(
          borderRadius: SproutRadii.card,
        ),
        imageAsset: SproutAssets.spotlightCamera,
      ),
      TutorialStepDefinition(
        key: targets.searchKey,
        title: 'Discover recipes 🔎',
        description:
            "Search thousands of chef-crafted recipes, or filter by cooking time, dietary pattern, and favorite cuisines.",
        stepIndex: 1,
        totalSteps: totalCount,
        shapeBorder: const RoundedRectangleBorder(
          borderRadius: SproutRadii.borderPill,
        ),
        imageAsset: SproutAssets.spotlightSearch,
      ),
      TutorialStepDefinition(
        key: targets.pantryKey,
        title: 'Cook with what you have 🥗',
        description:
            "Sprout keeps track of ingredients in your pantry and automatically ranks delicious recipes you can cook with zero food waste.",
        stepIndex: 2,
        totalSteps: totalCount,
        shapeBorder: const RoundedRectangleBorder(
          borderRadius: SproutRadii.card,
        ),
        imageAsset: SproutAssets.spotlightCook,
      ),
      TutorialStepDefinition(
        key: targets.savedKey,
        title: 'Save & Plan 🛒',
        description:
            "Bookmark your favorite meals into custom collections and generate interactive grocery lists with one tap.",
        stepIndex: 3,
        totalSteps: totalCount,
        shapeBorder: const RoundedRectangleBorder(
          borderRadius: SproutRadii.borderMd,
        ),
        imageAsset: SproutAssets.spotlightSaved,
      ),
      TutorialStepDefinition(
        key: targets.profileKey,
        title: 'Make it yours 🌱',
        description:
            "Tailor dietary preferences, review completed recipes in your cook history, and personalize your kitchen rhythm.",
        stepIndex: 4,
        totalSteps: totalCount,
        shapeBorder: const RoundedRectangleBorder(
          borderRadius: SproutRadii.borderMd,
        ),
        imageAsset: SproutAssets.spotlightProfile,
      ),
    ];
  }

  static TutorialStepDefinition get scanner => getSteps()[0];
  static TutorialStepDefinition get search => getSteps()[1];
  static TutorialStepDefinition get pantry => getSteps()[2];
  static TutorialStepDefinition get saved => getSteps()[3];
  static TutorialStepDefinition get profile => getSteps()[4];
}

/// Convenience wrapper widget binding a target widget to a [TutorialStepDefinition]
/// with Sprout's custom coach mark tooltip.
class SproutShowcase extends ConsumerWidget {
  final TutorialStepDefinition step;
  final Widget child;

  const SproutShowcase({
    super.key,
    required this.step,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(tutorialManagerProvider);

    return Showcase.withWidget(
      key: step.key,
      targetShapeBorder: step.shapeBorder,
      // 6px breathing room so the cutout doesn't hug the widget edges
      targetPadding: const EdgeInsets.all(6),
      overlayOpacity: 0.58,
      disableBarrierInteraction: true,
      container: SproutCoachMark(
        title: step.title,
        description: step.description,
        stepIndex: step.stepIndex,
        totalSteps: step.totalSteps,
        imageAsset: step.imageAsset,
        onNext: () => manager.next(context),
        onBack: step.stepIndex > 0 ? () => manager.previous(context) : null,
        onSkip: () => manager.skip(context),
        onDone: () => manager.complete(context),
      ),
      child: child,
    );
  }
}
