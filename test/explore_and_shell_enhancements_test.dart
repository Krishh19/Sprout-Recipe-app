import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/components/sprout_glass_nav.dart';
import 'package:sprout/design/components/sprout_scaffold.dart';
import 'package:sprout/features/main_shell_screen.dart';
import 'package:sprout/features/scanner/scanner_screen.dart';
import 'package:sprout/features/search/search_screen.dart';
import 'package:sprout/providers/app_providers.dart';

import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/recipe_repository.dart';

class _FakeDarkThemeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() {
    SproutColors.setDarkMode(true);
    return ThemeMode.dark;
  }
}

class _MockAlphabeticalRecipeRepository extends RecipeRepository {
  @override
  Future<List<Recipe>> searchRecipes({
    required String query,
    int? maxTime,
    String? cuisine,
    List<String>? diets,
    int page = 0,
    int pageSize = 20,
  }) async {
    return [
      const Recipe(
        id: 'z-1',
        title: 'Zucchini Fritters',
        description: 'Crispy zucchini snacks',
        ingredients: ['Zucchini', 'Flour'],
        cleanedIngredients: ['zucchini', 'flour'],
        instructions: ['Grate and fry'],
        totalTimeMins: 15,
        servings: 2,
        cuisine: 'Mediterranean',
      ),
      const Recipe(
        id: 'a-1',
        title: 'Apple Crisp',
        description: 'Warm baked apples',
        ingredients: ['Apples', 'Oats'],
        cleanedIngredients: ['apples', 'oats'],
        instructions: ['Bake and serve'],
        totalTimeMins: 30,
        servings: 4,
        cuisine: 'American',
      ),
      const Recipe(
        id: 'm-1',
        title: 'Mango Lassi',
        description: 'Refreshing yogurt drink',
        ingredients: ['Mango', 'Yogurt'],
        cleanedIngredients: ['mango', 'yogurt'],
        instructions: ['Blend together'],
        totalTimeMins: 5,
        servings: 1,
        cuisine: 'Indian',
      ),
    ];
  }
}

void main() {
  group('Full-Screen & Collapsible Header Architecture Tests', () {
    testWidgets('SproutScaffold renders status bar scrim when showStatusBarScrim is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
            child: const SproutScaffold(
              showStatusBarScrim: true,
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      // Verify BackdropFilter is rendered in status bar area
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('SearchScreen renders CustomScrollView with pinned sticky header and 2-column grid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      // Verify CustomScrollView is used
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Verify SliverAppBar is used with pinned sticky header
      final sliverAppBarFinder = find.byType(SliverAppBar);
      expect(sliverAppBarFinder, findsOneWidget);

      final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
      expect(sliverAppBar.pinned, isTrue);

      // Verify "Explore recipes" section header and "See all" action
      expect(find.text('Explore recipes'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('MainShellScreen wraps SproutGlassNav in AnimatedSlide for auto-hiding', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(),
          ),
        ),
      );

      // Verify AnimatedSlide wraps SproutGlassNav
      final animatedSlideFinder = find.ancestor(
        of: find.byType(SproutGlassNav),
        matching: find.byType(AnimatedSlide),
      );
      expect(animatedSlideFinder, findsOneWidget);

      final animatedSlide = tester.widget<AnimatedSlide>(animatedSlideFinder);
      // Initial state is visible at Offset.zero
      expect(animatedSlide.offset, Offset.zero);
    });

    testWidgets('ScannerScreen synchronizes theme mode and adapts mode tab colors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(() => _FakeDarkThemeNotifier()),
          ],
          child: MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(),
            home: const ScannerScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify SproutColors.isDarkMode is true
      expect(SproutColors.isDarkMode, isTrue);
      expect(SproutColors.canvas, equals(SproutColors.nightCanvas));
      expect(find.text('AI Vision'), findsOneWidget);
      expect(find.text('Barcode'), findsOneWidget);
    });

    testWidgets('SearchScreen renders recipes in alphabetical order by title in 2-column grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(_MockAlphabeticalRecipeRepository()),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appleFinder = find.text('Apple Crisp');
      final mangoFinder = find.text('Mango Lassi');
      final zucchiniFinder = find.text('Zucchini Fritters');

      expect(appleFinder, findsOneWidget);
      expect(mangoFinder, findsOneWidget);
      expect(zucchiniFinder, findsOneWidget);

      final applePos = tester.getTopLeft(appleFinder);
      final mangoPos = tester.getTopLeft(mangoFinder);
      final zucchiniPos = tester.getTopLeft(zucchiniFinder);

      // In a 2-column grid:
      // Row 0: Apple Crisp (left) and Mango Lassi (right)
      expect(applePos.dx < mangoPos.dx, isTrue, reason: 'Apple Crisp should appear to the left of Mango Lassi in Row 0');
      expect((applePos.dy - mangoPos.dy).abs() < 5.0, isTrue, reason: 'Apple Crisp and Mango Lassi should be on the same row');

      // Row 1: Zucchini Fritters is in the subsequent row below Row 0
      expect(applePos.dy < zucchiniPos.dy, isTrue, reason: 'Zucchini Fritters should appear on the row below Apple Crisp');
      expect(mangoPos.dy < zucchiniPos.dy, isTrue, reason: 'Zucchini Fritters should appear on the row below Mango Lassi');
    });
  });
}

