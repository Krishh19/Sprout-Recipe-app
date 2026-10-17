import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/sprout_ingredient_scaler.dart';

void main() {
  group('SproutIngredientScaler Tests', () {
    test('Returns original ingredient when scale is 1.0', () {
      expect(SproutIngredientScaler.scale('250g Paneer', 1.0), '250g Paneer');
      expect(SproutIngredientScaler.scale('Salt to taste', 1.0), 'Salt to taste');
    });

    test('Scales integer quantities correctly', () {
      expect(SproutIngredientScaler.scale('2 cups Fresh Spinach', 2.0), '4 cups Fresh Spinach');
      expect(SproutIngredientScaler.scale('4 medium Potatoes', 0.5), '2 medium Potatoes');
    });

    test('Scales metric weights and volumes correctly', () {
      expect(SproutIngredientScaler.scale('250 g Paneer', 2.0), '500 g Paneer');
      expect(SproutIngredientScaler.scale('100 ml Milk', 3.0), '300 ml Milk');
    });

    test('Scales simple fractions correctly', () {
      expect(SproutIngredientScaler.scale('1/2 tsp Turmeric powder', 2.0), '1 tsp Turmeric powder');
      expect(SproutIngredientScaler.scale('1/4 cup Yogurt', 2.0), '½ cup Yogurt');
    });

    test('Scales decimals correctly', () {
      expect(SproutIngredientScaler.scale('1.5 tbsp Cumin seeds', 2.0), '3 tbsp Cumin seeds');
    });

    test('Leaves unmeasured seasonings untouched', () {
      expect(SproutIngredientScaler.scale('Salt to taste', 2.0), 'Salt to taste');
      expect(SproutIngredientScaler.scale('Oil as required', 2.0), 'Oil as required');
      expect(SproutIngredientScaler.scale('Fresh coriander for garnish', 3.0), 'Fresh coriander for garnish');
    });
  });
}
