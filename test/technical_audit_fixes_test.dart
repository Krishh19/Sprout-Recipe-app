import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/ingredient_matcher.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/substitution_service.dart';

void main() {
  group('1.1 Substring Ingredient Matching Tests (IngredientMatcher)', () {
    test('blocks false positive butter matching peanut butter', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'butter', recipeIngredient: '1 cup peanut butter'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'butter', recipeIngredient: '2 tbsp almond butter'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'butter', recipeIngredient: 'buttermilk pancakes'),
        isFalse,
      );
    });

    test('matches real butter variants correctly', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'butter', recipeIngredient: '2 tbsp unsalted butter, softened'),
        isTrue,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'butter', recipeIngredient: '1/2 cup butter'),
        isTrue,
      );
    });

    test('blocks milk matching coconut milk or soy milk', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'milk', recipeIngredient: '1 cup coconut milk'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'milk', recipeIngredient: '1 cup soy milk'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'milk', recipeIngredient: '1/2 cup whole milk'),
        isTrue,
      );
    });

    test('blocks apple matching pineapple', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'apple', recipeIngredient: 'fresh pineapple slices'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'apple', recipeIngredient: '2 diced apples'),
        isTrue,
      );
    });

    test('blocks pepper matching bell pepper for black pepper and vice versa', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'pepper', recipeIngredient: '1 red bell pepper'),
        isFalse,
      );
    });

    test('blocks single-word pantry staple matching compound modifiers without matching token', () {
      expect(
        IngredientMatcher.isMatch(userItem: 'oil', recipeIngredient: '1 tbsp sesame oil'),
        isFalse,
      );
      expect(
        IngredientMatcher.isMatch(userItem: 'sesame oil', recipeIngredient: '1 tbsp sesame oil'),
        isTrue,
      );
    });
  });

  group('1.3 Dietary Classification Dynamic Detection (DietaryBadge)', () {
    test('classifies peanut butter cookies containing egg as egg badge', () {
      final badge = resolveDietaryBadge([
        '1 cup peanut butter',
        '1/2 cup sugar',
        '1 egg',
        '1 tsp vanilla extract',
      ]);
      expect(badge, equals(DietaryBadge.egg));
    });

    test('classifies pure veg recipes as veg badge', () {
      final badge = resolveDietaryBadge([
        'Paneer',
        'Bell Pepper',
        'Onions',
        'Tomatoes',
        'Garam Masala',
      ]);
      expect(badge, equals(DietaryBadge.veg));
    });

    test('classifies chicken recipes as non-veg badge', () {
      final badge = resolveDietaryBadge([
        'Chicken breast',
        'Garlic',
        'Olive oil',
      ]);
      expect(badge, equals(DietaryBadge.nonVeg));
    });

    test('respects defaultDiet=non-veg flag as nonVeg', () {
      final badge = resolveDietaryBadge([
        'Broccoli',
        'Olive oil',
      ], defaultDiet: 'non-veg');
      expect(badge, equals(DietaryBadge.nonVeg));
    });
  });

  group('1.4 Category-Aware Pantry Substitutions', () {
    test('suggests sweet baking alternatives for dessert recipes missing sugar', () {
      final fallback = SubstitutionService.createSmartFallback(
        '1/2 cup Sugar',
        recipeCategory: 'Dessert',
        recipeTitle: 'Peanut Butter Cookies',
      );

      final combined = '${fallback.substitute} ${fallback.culinaryTip} ${fallback.rationale}'.toLowerCase();
      expect(combined.contains('jaggery') || combined.contains('honey') || combined.contains('brown sugar'), isTrue);
      expect(combined.contains('salt and warming spices'), isFalse);
    });

    test('suggests savory balancing alternatives for curry recipes missing sugar', () {
      final fallback = SubstitutionService.createSmartFallback(
        '1 tsp Sugar',
        recipeCategory: 'Curry',
        recipeTitle: 'Gujarati Dal',
      );

      final combined = '${fallback.substitute} ${fallback.culinaryTip} ${fallback.rationale}'.toLowerCase();
      expect(combined.contains('caramelized onions') || combined.contains('jaggery') || combined.contains('acidity'), isTrue);
    });
  });

  group('1.5 Degree Symbol Sanitization (RecipeTextSanitizer)', () {
    test('sanitizes 350oF and 180oC to 350°F and 180°C', () {
      const input = 'Preheat oven to 350oF (180oC) and bake for 12 minutes.';
      expect(input.sanitizeDegreeSymbols(), equals('Preheat oven to 350°F (180°C) and bake for 12 minutes.'));
    });

    test('sanitizes 90o angle to 90° angle', () {
      const input = 'Hold spatula at a 90o angle while scraping.';
      expect(input.sanitizeDegreeSymbols(), equals('Hold spatula at a 90° angle while scraping.'));
    });
  });
}
