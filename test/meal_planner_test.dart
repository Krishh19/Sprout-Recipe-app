import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/models/meal_plan_item.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/meal_plan_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testRecipe = Recipe(
    id: 'test-recipe-1',
    title: 'Sprout Paneer Bowl',
    description: 'A protein-packed paneer dish',
    ingredients: ['200g Paneer', '1 Onion', '1 Tomato', '1/2 tsp Salt'],
    cleanedIngredients: ['paneer', 'onion', 'tomato', 'salt'],
    instructions: ['Dice paneer', 'Sauté onion and tomato', 'Fold in paneer'],
    totalTimeMins: 20,
    cuisine: 'Indian',
    imageUrl: 'https://images.unsplash.com/test.jpg',
    diet: 'veg',
  );

  group('MealPlanItem Model Tests', () {
    test('Serializes to and from JSON faithfully', () {
      final item = MealPlanItem(
        id: 'plan-101',
        dayOfWeek: 1, // Monday
        mealType: MealType.breakfast,
        recipe: testRecipe,
        note: 'Make with extra spice',
        createdAt: DateTime(2026, 10, 5, 8, 30),
      );

      final json = item.toJson();
      expect(json['id'], 'plan-101');
      expect(json['day_of_week'], 1);
      expect(json['meal_type'], 'breakfast');
      expect(json['note'], 'Make with extra spice');

      final deserialized = MealPlanItem.fromJson(json);
      expect(deserialized.id, item.id);
      expect(deserialized.dayOfWeek, 1);
      expect(deserialized.mealType, MealType.breakfast);
      expect(deserialized.recipe.title, testRecipe.title);
      expect(deserialized.note, 'Make with extra spice');
    });

    test('copyWith updates properties properly', () {
      final item = MealPlanItem(
        id: 'plan-102',
        dayOfWeek: 2,
        mealType: MealType.lunch,
        recipe: testRecipe,
        createdAt: DateTime.now(),
      );

      final updated = item.copyWith(
        mealType: MealType.dinner,
        note: 'Switched to dinner',
      );

      expect(updated.mealType, MealType.dinner);
      expect(updated.note, 'Switched to dinner');
      expect(updated.dayOfWeek, 2);
    });
  });

  group('MealPlanRepository Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Adds and retrieves meal plan items', () async {
      final repo = MealPlanRepository();
      expect(await repo.fetchMealPlan(), isEmpty);

      final item = MealPlanItem(
        id: 'mon-lunch',
        dayOfWeek: 1,
        mealType: MealType.lunch,
        recipe: testRecipe,
        createdAt: DateTime.now(),
      );

      final updated = await repo.addOrUpdateItem(item);
      expect(updated.length, 1);
      expect(updated.first.recipe.title, 'Sprout Paneer Bowl');

      final fetched = await repo.fetchMealPlan();
      expect(fetched.length, 1);
      expect(fetched.first.id, 'mon-lunch');
    });

    test('Replaces existing meal slot on the same day', () async {
      final repo = MealPlanRepository();
      final item1 = MealPlanItem(
        id: 'mon-lunch-1',
        dayOfWeek: 1,
        mealType: MealType.lunch,
        recipe: testRecipe,
        createdAt: DateTime.now(),
      );
      await repo.addOrUpdateItem(item1);

      final newRecipe = testRecipe.copyWith(
        id: 'test-recipe-2',
        title: 'Dal Makhani',
      );
      final item2 = MealPlanItem(
        id: 'mon-lunch-2',
        dayOfWeek: 1,
        mealType: MealType.lunch,
        recipe: newRecipe,
        createdAt: DateTime.now(),
      );

      final updated = await repo.addOrUpdateItem(item2);
      expect(updated.length, 1);
      expect(updated.first.recipe.title, 'Dal Makhani');
    });

    test('Removes meal and clears week', () async {
      final repo = MealPlanRepository();
      final item = MealPlanItem(
        id: 'fri-dinner',
        dayOfWeek: 5,
        mealType: MealType.dinner,
        recipe: testRecipe,
        createdAt: DateTime.now(),
      );
      await repo.addOrUpdateItem(item);
      expect((await repo.fetchMealPlan()).length, 1);

      final afterRemove = await repo.removeItem('fri-dinner');
      expect(afterRemove, isEmpty);

      await repo.addOrUpdateItem(item);
      final afterClear = await repo.clearWeek();
      expect(afterClear, isEmpty);
    });
  });
}
