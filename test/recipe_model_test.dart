import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/food_image_helper.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/recipe_repository.dart';

void main() {
  group('Recipe Model Tests', () {
    test('Recipe parses correctly from CSV-like JSON format with safe defaults', () {
      final json = {
        'id': 'rec-123',
        'TranslatedRecipeName': 'Paneer Butter Masala',
        'TranslatedIngredients': '250g Paneer, 3 Tomatoes, 2 Onions',
        'Cleaned-Ingredients': 'paneer, tomato, onion',
        'TranslatedInstructions': 'Sauté onions.\nAdd tomato puree.\nAdd paneer.',
        'TotalTimeInMins': 30,
        'Cuisine': 'North Indian',
        'image-url': 'https://example.com/paneer.jpg',
        'URL': 'https://example.com/recipe',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'rec-123');
      expect(recipe.title, 'Paneer Butter Masala');
      expect(recipe.totalTimeMins, 30);
      expect(recipe.cuisine, 'North Indian');
      expect(recipe.cleanedIngredients, contains('paneer'));
      expect(recipe.cleanedIngredients, contains('tomato'));
      expect(recipe.cleanedIngredients, contains('onion'));
      expect(recipe.instructions.length, 3);
      expect(recipe.instructions[0], 'Sauté onions.');
      expect(recipe.imageUrl, 'https://example.com/paneer.jpg');
      expect(recipe.diet, 'veg');
      expect(recipe.rating, isNull, reason: 'Recipes without ratings must NOT default to fake 4.8');
      expect(recipe.reviewCount, 0);
    });

    test('Recipe parses database row with explicit diet and rating', () {
      final row = {
        'id': 'rec-456',
        'title': 'Egg Curry',
        'total_time_mins': 25,
        'cuisine': 'South Indian',
        'diet': 'egg',
        'rating': 4.5,
        'review_count': 12,
        'cleaned_ingredients': ['boiled egg', 'onion', 'curry leaves'],
      };

      final recipe = Recipe.fromJson(row);

      expect(recipe.id, 'rec-456');
      expect(recipe.title, 'Egg Curry');
      expect(recipe.diet, 'egg');
      expect(recipe.rating, 4.5);
      expect(recipe.reviewCount, 12);
      expect(recipe.cleanedIngredients, contains('boiled egg'));
    });

    test('Recipe.copyWith updates match percentage, diet, and saved status', () {
      const recipe = Recipe(
        id: '1',
        title: 'Dal Fry',
        description: 'Comforting lentil curry',
        ingredients: ['Dal', 'Ghee', 'Garlic'],
        cleanedIngredients: ['dal', 'ghee', 'garlic'],
        instructions: ['Boil dal', 'Temper with ghee and garlic'],
        totalTimeMins: 20,
        cuisine: 'Indian',
        diet: 'veg',
      );

      final updated = recipe.copyWith(
        isSaved: true,
        matchPercentage: 85.5,
        matchedIngredients: ['dal', 'garlic'],
        missingIngredients: ['ghee'],
        diet: 'veg',
      );

      expect(updated.isSaved, true);
      expect(updated.matchPercentage, 85.5);
      expect(updated.matchedIngredients.length, 2);
      expect(updated.missingIngredients, ['ghee']);
      expect(updated.diet, 'veg');
    });

    test('FoodImageHelper validates URLs and drops unverified/scraped links', () {
      expect(FoodImageHelper.hasValidRecipeImage(null), isFalse);
      expect(FoodImageHelper.hasValidRecipeImage(''), isFalse);
      expect(FoodImageHelper.hasValidRecipeImage('   '), isFalse);
      expect(
        FoodImageHelper.hasValidRecipeImage('https://www.archanaskitchen.com/images/recipe.jpg'),
        isFalse,
        reason: 'Scraped Archana\'s Kitchen URLs should be marked invalid due to mobile failure',
      );
      expect(
        FoodImageHelper.hasValidRecipeImage('https://images.unsplash.com/photo-12345'),
        isTrue,
      );

      // getValidImageUrl drops fake stock mapping and returns null for unverified
      final archanasResult = FoodImageHelper.getValidImageUrl(
        originalUrl: 'https://www.archanaskitchen.com/images/karela.jpg',
        title: 'Masala Karela',
        cuisine: 'Indian',
      );
      expect(archanasResult, isNull, reason: 'Caller should fall back to authentic CuisinePlaceholder');

      final emptyResult = FoodImageHelper.getValidImageUrl(
        originalUrl: '',
        title: 'Crispy Aloo Jeera',
        cuisine: 'North Indian',
      );
      expect(emptyResult, isNull);

      final validUrl = 'https://images.unsplash.com/photo-1546833999-b9f581a1996d';
      final validResult = FoodImageHelper.getValidImageUrl(
        originalUrl: validUrl,
        title: 'Masala Karela',
        cuisine: 'Indian',
      );
      expect(validResult, equals(validUrl));

      // resolveRecipeImageUrl reliably resolves food photography for any recipe
      final biryaniResolved = FoodImageHelper.resolveRecipeImageUrl(
        originalUrl: 'https://www.archanaskitchen.com/images/biryani.jpg',
        title: 'Hyderabadi Chicken Biryani',
        cuisine: 'Indian',
      );
      expect(biryaniResolved, startsWith('https://images.unsplash.com/'));
      expect(biryaniResolved, equals(FoodImageHelper.resolveRecipeImageUrl(
        originalUrl: null,
        title: 'Hyderabadi Chicken Biryani',
        cuisine: 'Indian',
      )), reason: 'Deterministic hashing must return same photo for same recipe title');

      final paneerResolved = FoodImageHelper.resolveRecipeImageUrl(
        originalUrl: null,
        title: 'Paneer Butter Masala',
        cuisine: 'North Indian',
      );
      expect(paneerResolved, contains('photo-1631452180519-c014fe946bc7'));

      final validKept = FoodImageHelper.resolveRecipeImageUrl(
        originalUrl: 'https://custom-host.com/real-dish.jpg',
        title: 'Random Dish',
        cuisine: 'Indian',
      );
      expect(validKept, equals('https://custom-host.com/real-dish.jpg'));
    });

    test('RecipeRepository.parseRows parses valid rows and skips malformed rows safely', () {
      final rows = [
        {
          'id': '1',
          'title': 'Dal Tadka',
          'total_time_mins': 25,
          'cuisine': 'Indian',
          'diet': 'veg',
        },
        // Malformed row: invalid non-map entry
        'invalid_non_map_row',
        {
          'id': '2',
          'title': 'Jeera Rice',
          'total_time_mins': 20,
          'cuisine': 'Indian',
          'diet': 'veg',
        },
      ];

      final recipes = RecipeRepository.parseRows(rows);

      expect(recipes.length, 2, reason: 'Malformed row should be skipped without aborting other rows');
      expect(recipes[0].id, '1');
      expect(recipes[0].title, 'Dal Tadka');
      expect(recipes[1].id, '2');
      expect(recipes[1].title, 'Jeera Rice');
    });

    test('Fallback recipe fb-4 (Crispy Aloo Jeera) uses authentic potato image and diet tag', () {
      final fb4 = RecipeRepository.fallbackRecipes.firstWhere((r) => r.id == 'fb-4');
      const idliPhoto = 'photo-1589301760014-d929f3979dbc';

      expect(fb4.title, equals('Crispy Aloo Jeera'));
      expect(fb4.diet, equals('veg'));
      expect(fb4.imageUrl, contains('photo-1569603375125-66663722b0c5'));
      expect(fb4.imageUrl, isNot(contains(idliPhoto)));
    });
  });
}
