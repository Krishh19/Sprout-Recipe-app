import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/repositories/recipe_repository.dart';

void main() {
  group('RecipeRepository Semantic Intent Parsing', () {
    test('extracts time and clean query from natural language search', () {
      final intent = RecipeRepository.parseSearchIntent('quick pasta');
      expect(intent['maxTime'], 30);
      expect(intent['cleanQuery'], 'pasta');
    });

    test('extracts minute constraints like "under 20 mins"', () {
      final intent = RecipeRepository.parseSearchIntent('under 20 mins soup');
      expect(intent['maxTime'], 20);
      expect(intent['cleanQuery'], 'soup');
    });

    test('extracts vegan dietary preference', () {
      final intent = RecipeRepository.parseSearchIntent('vegan curry');
      expect(intent['diets'], contains('vegan'));
      expect(intent['cleanQuery'], 'curry');
    });

    test('extracts vegetarian dietary preference with time', () {
      final intent = RecipeRepository.parseSearchIntent('quick vegetarian biryani');
      expect(intent['maxTime'], 30);
      expect(intent['diets'], contains('vegetarian'));
      expect(intent['cleanQuery'], 'biryani');
    });

    test('handles queries without intents cleanly', () {
      final intent = RecipeRepository.parseSearchIntent('paneer butter masala');
      expect(intent['maxTime'], isNull);
      expect(intent['diets'], isEmpty);
      expect(intent['cleanQuery'], 'paneer butter masala');
    });
  });
}
