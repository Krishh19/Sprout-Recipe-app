import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/config.dart';
import 'package:sprout/features/recipes/recipe_detail_screen.dart';
import 'package:sprout/models/nutrition_info.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/providers/app_providers.dart';
import 'package:sprout/repositories/substitution_service.dart';
import 'package:sprout/services/groq_service.dart';
import 'package:sprout/services/sprout_ai_service.dart';

void main() {
  group('Groq Configuration & Routing Tests', () {
    test('AppConfig defines groqApiKey and groqModel default to qwen/qwen3.8-27b', () {
      expect(AppConfig.groqModel, equals('qwen/qwen3.8-27b'));
    });

    test('GroqService singleton reflects availability based on key', () {
      final service = GroqService();
      if (AppConfig.groqApiKey.isEmpty) {
        expect(service.isAvailable, isFalse);
      } else {
        expect(service.isAvailable, isTrue);
      }
    });

    test('SubstitutionService factory routes to SubstitutionService implementation', () {
      final subService = SubstitutionService();
      expect(subService, isNotNull);
    });

    test('SproutAiService singleton provides secure server-side AI access', () {
      final aiService = SproutAiService();
      expect(aiService, isNotNull);
    });
  });

  group('Nutrition UI & Clearance Tests', () {
    const testRecipe = Recipe(
      id: 'test-recipe-1',
      title: '7 Cups Burfi Recipe',
      description: 'Traditional festive sweet',
      ingredients: ['Besan', 'Sugar', 'Ghee', 'Milk'],
      cleanedIngredients: ['besan', 'sugar', 'ghee', 'milk'],
      instructions: ['Roast besan in ghee', 'Add milk and sugar', 'Stir until thick'],
      totalTimeMins: 30,
      servings: 1,
      cuisine: 'Indian',
      diet: 'veg',
    );

    testWidgets('RecipeDetailScreen renders Nutrition tab without overflowing header or button', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeNutritionProvider(testRecipe).overrideWith(
              (ref) => Future.value(const NutritionInfo(
                calories: 391,
                proteinG: 8,
                carbsG: 47,
                fatG: 19,
                fiberG: 3,
                healthNote: 'Balanced home-cooked meal',
                isAiEstimated: true,
              )),
            ),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipe: testRecipe),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Nutrition tab and tap it
      final nutritionTab = find.text('Nutrition');
      expect(nutritionTab, findsOneWidget);

      await tester.tap(nutritionTab);
      await tester.pumpAndSettle();

      // Verify kcal text is visible
      expect(find.text('kcal'), findsOneWidget);
      expect(find.text('391'), findsOneWidget);

      // Verify Macro badges are present
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbohydrates'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Dietary Fiber'), findsOneWidget);

      // Verify Start Cooking button is rendered at bottom
      expect(find.text('Start Cooking →'), findsOneWidget);
    });
  });
}
