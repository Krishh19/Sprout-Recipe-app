import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/search/search_screen.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/providers/app_providers.dart';
import 'package:sprout/repositories/recipe_repository.dart';

class _CapturingRecipeRepository extends RecipeRepository {
  List<String>? lastCuisines;
  int? lastMaxTime;
  String? lastQuery;

  @override
  Future<List<Recipe>> searchRecipes({
    required String query,
    int? maxTime,
    String? cuisine,
    List<String>? cuisines,
    List<String>? diets,
    int page = 0,
    int pageSize = 20,
  }) async {
    lastQuery = query;
    lastMaxTime = maxTime;
    lastCuisines = cuisines;

    return [
      const Recipe(
        id: 'r-1',
        title: 'Butter Chicken',
        description: 'Rich creamy chicken curry',
        ingredients: ['Chicken', 'Butter', 'Cream'],
        cleanedIngredients: ['chicken', 'butter', 'cream'],
        instructions: ['Cook chicken', 'Add sauce'],
        totalTimeMins: 35,
        servings: 2,
        cuisine: 'Indian',
      ),
      const Recipe(
        id: 'r-2',
        title: 'Margherita Pizza',
        description: 'Classic cheese and tomato pizza',
        ingredients: ['Dough', 'Mozzarella', 'Tomato'],
        cleanedIngredients: ['dough', 'mozzarella', 'tomato'],
        instructions: ['Bake at 250C'],
        totalTimeMins: 20,
        servings: 2,
        cuisine: 'Italian',
      ),
    ];
  }
}

void main() {
  group('SearchScreen Multi-Select & Pinned Apply Button Tests', () {
    testWidgets('Filter sheet has directly accessible Apply Filters button without scrolling and supports multi-select cuisines', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _CapturingRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter icon in search bar to open bottom sheet
      final filterIcon = find.byIcon(Icons.tune_rounded);
      expect(filterIcon, findsOneWidget);
      await tester.tap(filterIcon);
      await tester.pumpAndSettle();

      // Verify the bottom sheet opened
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Cooking Time (Max)'), findsOneWidget);
      expect(find.text('Cuisines'), findsOneWidget);

      // Verify "Apply Filters" button is DIRECTLY ACCESSIBLE / VISIBLE without scrolling
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply Filters');
      expect(applyButton, findsOneWidget);

      // Select multiple cuisines: Italian and Indian
      final italianChip = find.widgetWithText(FilterChip, 'Italian');
      final indianChip = find.widgetWithText(FilterChip, 'Indian');

      expect(italianChip, findsOneWidget);
      expect(indianChip, findsOneWidget);

      await tester.tap(italianChip);
      await tester.pumpAndSettle();

      await tester.tap(indianChip);
      await tester.pumpAndSettle();

      // Check header count badge and apply button label showing count
      expect(find.text('2 selected'), findsOneWidget);
      final applyButtonWithCount = find.widgetWithText(ElevatedButton, 'Apply Filters (2)');
      expect(applyButtonWithCount, findsOneWidget);

      // Tap the directly accessible Apply button
      await tester.tap(applyButtonWithCount);
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.text('Filters'), findsNothing);

      // Verify repository received both cuisines
      expect(repo.lastCuisines, containsAll(['Italian', 'Indian']));

      // Verify active filter chips are rendered in horizontal list
      expect(find.widgetWithText(InputChip, 'Italian'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Indian'), findsOneWidget);

      // Test removing one active filter directly from chip
      final deleteIndianIcon = find.descendant(
        of: find.widgetWithText(InputChip, 'Indian'),
        matching: find.byType(Icon),
      );
      await tester.tap(deleteIndianIcon);
      await tester.pumpAndSettle();

      // Now only Italian is left
      expect(find.widgetWithText(InputChip, 'Italian'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Indian'), findsNothing);
      expect(repo.lastCuisines, equals(['Italian']));
    });
  });
}
