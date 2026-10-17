import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/models/nutrition_info.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/nutrition_service.dart';

void main() {
  group('NutritionInfo Model Tests', () {
    test('serializes to and from JSON accurately', () {
      const info = NutritionInfo(
        calories: 450,
        proteinG: 28,
        carbsG: 40,
        fatG: 16,
        fiberG: 5,
        healthNote: 'High protein energy meal',
        isAiEstimated: true,
      );

      final json = info.toJson();
      final fromJson = NutritionInfo.fromJson(json);

      expect(fromJson.calories, equals(450));
      expect(fromJson.proteinG, equals(28));
      expect(fromJson.carbsG, equals(40));
      expect(fromJson.fatG, equals(16));
      expect(fromJson.fiberG, equals(5));
      expect(fromJson.healthNote, equals('High protein energy meal'));
      expect(fromJson.isAiEstimated, isTrue);
    });

    test('scales correctly with servings factor', () {
      const info = NutritionInfo(
        calories: 300,
        proteinG: 10,
        carbsG: 40,
        fatG: 8,
        fiberG: 4,
      );

      final scaled = info.scale(2.0);
      expect(scaled.calories, equals(600));
      expect(scaled.proteinG, equals(20));
      expect(scaled.carbsG, equals(80));
      expect(scaled.fatG, equals(16));
      expect(scaled.fiberG, equals(8));
    });
  });

  group('NutritionService Culinary Heuristic Tests', () {
    test('detects high protein ingredients accurately', () {
      const chickenRecipe = Recipe(
        id: 'rec-1',
        title: 'Grilled Lemon Chicken Breast',
        description: 'Lean chicken recipe',
        ingredients: ['500g chicken breast', '2 tbsp olive oil', '1 lemon'],
        cleanedIngredients: ['chicken breast', 'olive oil', 'lemon'],
        instructions: ['Grill chicken and serve.'],
        totalTimeMins: 25,
        cuisine: 'Mediterranean',
        servings: 2,
      );

      final info = NutritionService.calculateHeuristicNutrition(chickenRecipe);
      expect(info.proteinG, greaterThanOrEqualTo(25));
      expect(info.healthNote, contains('protein'));
    });

    test('detects plant protein and fiber in dal/lentil recipes', () {
      const dalRecipe = Recipe(
        id: 'rec-2',
        title: 'Tadka Dal Lentil Soup',
        description: 'Yellow lentils tempered with cumin',
        ingredients: ['1 cup toor dal', '1 tsp cumin', '1 tomato', 'spinach'],
        cleanedIngredients: ['toor dal', 'cumin', 'tomato', 'spinach'],
        instructions: ['Pressure cook dal and temper.'],
        totalTimeMins: 30,
        cuisine: 'Indian',
        servings: 4,
      );

      final info = NutritionService.calculateHeuristicNutrition(dalRecipe);
      expect(info.proteinG, greaterThanOrEqualTo(14));
      expect(info.fiberG, greaterThanOrEqualTo(6));
      expect(info.healthNote, contains('fiber'));
    });
  });
}
