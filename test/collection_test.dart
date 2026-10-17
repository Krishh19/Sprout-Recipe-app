import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/features/saved/collection_detail_screen.dart';
import 'package:sprout/models/collection.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/saved_repository.dart';

void main() {
  group('SavedRepository Collection Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('fetchCollections returns default collections with zero count', () async {
      final repo = SavedRepository();
      final colls = await repo.fetchCollections();

      expect(colls, isNotEmpty);
      expect(colls.first.recipeCount, 0);
    });

    test('addRecipeToCollection and fetchRecipesForCollection persist correctly', () async {
      final repo = SavedRepository();
      const testRecipe = Recipe(
        id: 'r-101',
        title: 'Paneer Tikka',
        description: 'Smoky grilled paneer cubes',
        ingredients: ['paneer', 'curd', 'spices'],
        cleanedIngredients: ['paneer'],
        instructions: ['Marinate and grill'],
        totalTimeMins: 20,
        cuisine: 'North Indian',
      );

      await repo.addRecipeToCollection('col-1', testRecipe);
      final recipes = await repo.fetchRecipesForCollection('col-1');

      expect(recipes.length, 1);
      expect(recipes.first.title, 'Paneer Tikka');

      await repo.removeRecipeFromCollection('col-1', 'r-101');
      final afterRemove = await repo.fetchRecipesForCollection('col-1');
      expect(afterRemove, isEmpty);
    });
  });

  group('CollectionDetailScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders empty state when collection has no recipes', (tester) async {
      bool exploreTapped = false;
      final coll = RecipeCollection(
        id: 'col-test',
        userId: 'local',
        name: 'Quick Lunches',
        description: 'Fast weekday meals',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CollectionDetailScreen(
              collection: coll,
              onExploreTap: () => exploreTapped = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quick Lunches'), findsOneWidget);
      expect(find.text('No recipes in Quick Lunches'), findsOneWidget);
      expect(find.text('Explore Recipes'), findsOneWidget);

      await tester.tap(find.text('Explore Recipes'));
      await tester.pump();
      expect(exploreTapped, isTrue);
    });
  });
}
