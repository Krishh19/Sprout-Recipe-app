import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/design/sprout_ingredient_formatter.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/shopping_repository.dart';

void main() {
  group('Recipe Title Cleaning & Formatting (Audit Section 2.1)', () {
    test('cleans long run-on title into 2-7 word display title and subtitle', () {
      const raw =
          'Parsi Style Sekta Ni Sing Recipe-Sweet & Spicy Drumsticks Cooked In Coconut Water/Toddy Recipe';
      final parts = RecipeTitleCleaner.clean(raw);

      expect(parts.displayTitle, 'Parsi-Style Sekta Ni Sing');
      expect(parts.displayTitle.split(' ').length, inInclusiveRange(2, 7));
      expect(parts.displayTitle.toLowerCase(), isNot(contains('recipe')));
      expect(parts.subtitle, isNotNull);
      expect(parts.subtitle!, contains('Drumsticks'));
    });

    test('strips trailing Recipe suffix and handles dash separator', () {
      const raw = 'Crispy Aloo Tikki Recipe - Street Style Potato Patties';
      final parts = RecipeTitleCleaner.clean(raw);

      expect(parts.displayTitle, 'Crispy Aloo Tikki');
      expect(parts.subtitle, 'Street Style Potato Patties');
    });

    test('handles standard recipe titles cleanly', () {
      const raw = 'Paneer Butter Masala Recipe';
      final parts = RecipeTitleCleaner.clean(raw);

      expect(parts.displayTitle, 'Paneer Butter Masala');
      expect(parts.subtitle, isNull);
    });

    test('Recipe model displayTitle and subtitle getters work correctly', () {
      const recipe = Recipe(
        id: 'rec-1',
        title:
            'Parsi Style Sekta Ni Sing Recipe-Sweet & Spicy Drumsticks Cooked In Coconut Water/Toddy Recipe',
        description: 'Authentic Parsi drumsticks cooked in sweet coconut water',
        ingredients: ['Drumsticks', 'Coconut water'],
        cleanedIngredients: ['drumsticks', 'coconut water'],
        instructions: ['Heat oil and sauté.'],
        totalTimeMins: 35,
        cuisine: 'Parsi',
      );

      expect(recipe.title, contains('Toddy Recipe'),
          reason: 'Raw title is preserved for backward compatibility');
      expect(recipe.displayTitle, 'Parsi-Style Sekta Ni Sing');
      expect(recipe.subtitle, isNotNull);
    });
  });

  group('Ingredient Normalization & Alias Mapping (Audit Section 5.1 & 6)', () {
    test('normalizes Indian aliases and removes preparation descriptors', () {
      expect(
        SproutIngredientFormatter.normalizeGroceryName(
          '½ cup Coriander (Dhania) Leaves, a small bunch finely chopped',
        ),
        'Coriander',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('Dhania Leaves'),
        'Coriander',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('Green Chilli'),
        'Green Chillies',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('Green Chillies'),
        'Green Chillies',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('Hari Mirch'),
        'Green Chillies',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('2 onions - finely chopped'),
        'Onion',
      );

      expect(
        SproutIngredientFormatter.normalizeGroceryName('Ginger-garlic paste'),
        'Ginger Garlic Paste',
      );
    });

    test('parses ingredient into canonical ParsedIngredient', () {
      final parsed = SproutIngredientFormatter.parseIngredient(
        '½ cup Coriander (Dhania) Leaves, a small bunch finely chopped',
      );

      expect(parsed.primaryName, 'Coriander');
      expect(parsed.displayQuantity, '½ cup · 1 small bunch');
      expect(parsed.numericAmount, 0.5);
      expect(parsed.unit, 'cup');
      expect(parsed.category, 'Fresh Produce');
    });

    test('categorizes into 9 official grocery categories', () {
      expect(SproutIngredientFormatter.categorizeGrocery('Coriander'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorizeGrocery('Paneer'), 'Dairy');
      expect(SproutIngredientFormatter.categorizeGrocery('Basmati Rice'), 'Grains & Pantry');
      expect(SproutIngredientFormatter.categorizeGrocery('Turmeric Powder'), 'Herbs & Spices');
      expect(SproutIngredientFormatter.categorizeGrocery('Chicken Breast'), 'Meat & Seafood');
      expect(SproutIngredientFormatter.categorizeGrocery('Frozen Peas'), 'Frozen');
      expect(SproutIngredientFormatter.categorizeGrocery('Soy Sauce'), 'Condiments & Sauces');
      expect(SproutIngredientFormatter.categorizeGrocery('Coconut Water'), 'Beverages');
    });

    test('formats combined quantities with unicode fractions', () {
      expect(
        SproutIngredientFormatter.formatCombinedQuantity(1.5, 'cup'),
        '1½ cups',
      );

      expect(
        SproutIngredientFormatter.formatCombinedQuantity(2.0, 'tbsp'),
        '2 tbsp',
      );

      expect(
        SproutIngredientFormatter.formatCombinedQuantity(0.75, 'cup'),
        '¾ cup',
      );
    });
  });

  group('Shopping Repository Duplicate Merging (Audit Section 6)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('merges duplicate ingredients and combines numeric quantities', () async {
      final repo = ShoppingRepository();

      // Add coriander from Recipe A (½ cup)
      await repo.addItems(
        ['½ cup Coriander (Dhania) Leaves, finely chopped'],
        recipeTitle: 'Parsi Style Sekta Ni Sing Recipe',
      );

      var items = await repo.fetchItems();
      expect(items.length, 1);
      expect(items[0].name, 'Coriander');
      expect(items[0].displayQuantity, '½ cup');
      expect(items[0].recipeTitle, 'Parsi-Style Sekta Ni Sing');
      expect(items[0].recipeCount, 1);

      // Add coriander from Recipe B (1 cup)
      await repo.addItems(
        ['1 cup coriander leaves'],
        recipeTitle: 'Dhaba Style Paneer Butter Masala Recipe',
      );

      items = await repo.fetchItems();
      expect(items.length, 1, reason: 'Duplicate coriander should be merged into single item');
      expect(items[0].name, 'Coriander');
      expect(items[0].displayQuantity, '1½ cups total');
      expect(items[0].recipeCount, 2);
    });

    test('preserves distinct ingredients without unintended merging', () async {
      final repo = ShoppingRepository();

      await repo.addItems(
        ['1 cup Paneer cubes', '2 Tomatoes'],
        recipeTitle: 'Paneer Butter Masala',
      );

      final items = await repo.fetchItems();
      expect(items.length, 2);
      expect(items.any((i) => i.name == 'Paneer'), isTrue);
      expect(items.any((i) => i.name == 'Tomato'), isTrue);
    });
  });
}
