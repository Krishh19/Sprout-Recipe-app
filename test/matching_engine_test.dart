import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/repositories/recipe_repository.dart';

void main() {
  group('Recipe Matching Engine Tests', () {
    final repo = RecipeRepository();

    test('matchRecipes correctly identifies highest match for paneer & tomato', () async {
      final matches = await repo.matchRecipes(
        userIngredients: ['paneer', 'tomato', 'butter'],
      );

      expect(matches.isNotEmpty, true);
      final topMatch = matches.first;

      // Paneer Butter Masala should be top ranked
      expect(topMatch.title, 'Paneer Butter Masala');
      expect(topMatch.matchedIngredients, contains('paneer'));
      expect(topMatch.matchedIngredients, contains('tomato'));
      expect(topMatch.matchPercentage, greaterThan(0));
    });

    test('matchRecipes returns empty when no ingredients provided', () async {
      final matches = await repo.matchRecipes(userIngredients: []);
      expect(matches.isEmpty, true);
    });
  });
}
