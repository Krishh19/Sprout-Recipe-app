import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/sprout_ingredient_formatter.dart';

void main() {
  group('SproutIngredientFormatter - normalize()', () {
    test('normalizes messy fraction formats to clean unicode fractions', () {
      expect(
        SproutIngredientFormatter.normalize('2-1 / 2 cups rice - cooked'),
        '2½ cups rice (cooked)',
      );
      expect(
        SproutIngredientFormatter.normalize('1-1/2 tablespoon oil'),
        '1½ tbsp oil',
      );
      expect(
        SproutIngredientFormatter.normalize('1/2 teaspoon cumin seeds'),
        '½ tsp cumin seeds',
      );
      expect(
        SproutIngredientFormatter.normalize('3/4 cup water'),
        '¾ cup water',
      );
      expect(
        SproutIngredientFormatter.normalize('1/4 cup chopped coriander'),
        '¼ cup (chopped) coriander',
      );
      expect(
        SproutIngredientFormatter.normalize('1/3 cup milk'),
        '⅓ cup milk',
      );
    });

    test('replaces awkward trailing dashes with parenthesis or clean separators', () {
      expect(
        SproutIngredientFormatter.normalize('2 onions - finely chopped'),
        '2 onions (chopped)',
      );
      expect(
        SproutIngredientFormatter.normalize('salt - to taste'),
        'Salt to taste',
      );
      expect(
        SproutIngredientFormatter.normalize('1 cup spinach - washed and chopped'),
        '1 cup spinach (washed) and (chopped)',
      );
    });

    test('strips surrounding quotes and brackets from dataset strings', () {
      expect(
        SproutIngredientFormatter.normalize('["2 tomatoes", "1 onion"]'),
        '2 tomatoes", "1 onion',
      );
      expect(
        SproutIngredientFormatter.normalize('"1 cup paneer"'),
        '1 cup paneer',
      );
    });

    test('handles empty and whitespace-only strings gracefully', () {
      expect(SproutIngredientFormatter.normalize(''), '');
      expect(SproutIngredientFormatter.normalize('   '), '');
    });
  });

  group('SproutIngredientFormatter - categorize() & getCategoryEmoji()', () {
    test('categorizes fresh produce correctly', () {
      expect(SproutIngredientFormatter.categorize('2 ripe tomatoes'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorize('1 bunch spinach'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorize('chopped onion'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorize('fresh coriander leaves'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorize('grated ginger'), 'Fresh Produce');
      expect(SproutIngredientFormatter.categorize('green chillies'), 'Fresh Produce');
    });

    test('categorizes dairy correctly', () {
      expect(SproutIngredientFormatter.categorize('200g paneer cubes'), 'Dairy & Refrigerated');
      expect(SproutIngredientFormatter.categorize('2 tbsp butter'), 'Dairy & Refrigerated');
      expect(SproutIngredientFormatter.categorize('1 cup whole milk'), 'Dairy & Refrigerated');
      expect(SproutIngredientFormatter.categorize('½ cup curd / yogurt'), 'Dairy & Refrigerated');
      expect(SproutIngredientFormatter.categorize('ghee for frying'), 'Dairy & Refrigerated');
    });

    test('categorizes grains, dal, and staples correctly', () {
      expect(SproutIngredientFormatter.categorize('1 cup basmati rice'), 'Grains & Staples');
      expect(SproutIngredientFormatter.categorize('½ cup toor dal'), 'Grains & Staples');
      expect(SproutIngredientFormatter.categorize('2 cups wheat flour (atta)'), 'Grains & Staples');
      expect(SproutIngredientFormatter.categorize('sooji / semolina'), 'Grains & Staples');
      expect(SproutIngredientFormatter.categorize('pasta or noodles'), 'Grains & Staples');
    });

    test('categorizes spices and seasonings correctly', () {
      expect(SproutIngredientFormatter.categorize('1 tsp cumin seeds (jeera)'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('½ tsp turmeric powder (haldi)'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('garam masala'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('mustard seeds (rai)'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('asafoetida (hing)'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('salt to taste'), 'Spices & Seasoning');
      expect(SproutIngredientFormatter.categorize('sunflower oil'), 'Spices & Seasoning');
    });

    test('falls back to Other Groceries for unknown items', () {
      expect(SproutIngredientFormatter.categorize('aluminum foil'), 'Other Groceries');
      expect(SproutIngredientFormatter.categorize('baking soda'), 'Other Groceries');
    });

    test('returns appropriate emojis for categories', () {
      expect(SproutIngredientFormatter.getCategoryEmoji('Fresh Produce'), '🥬');
      expect(SproutIngredientFormatter.getCategoryEmoji('Dairy & Refrigerated'), '🥛');
      expect(SproutIngredientFormatter.getCategoryEmoji('Grains & Staples'), '🌾');
      expect(SproutIngredientFormatter.getCategoryEmoji('Spices & Seasoning'), '🧂');
      expect(SproutIngredientFormatter.getCategoryEmoji('Other Groceries'), '📦');
    });
  });
}
