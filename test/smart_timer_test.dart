import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smart Cooking Timer Parsing Tests', () {
    int extractMinutes(String text) {
      final regExp = RegExp(r'(\d+)\s*(?:to\s*\d+\s*)?(?:minutes|mins|minute|min)');
      final match = regExp.firstMatch(text.toLowerCase());
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
      return 0;
    }

    test('extracts single minute values', () {
      expect(extractMinutes('Simmer on low heat for 15 minutes.'), 15);
      expect(extractMinutes('Bake for 30 mins until golden.'), 30);
      expect(extractMinutes('Cover and cook for 1 minute.'), 1);
    });

    test('extracts lower bound from range durations', () {
      expect(extractMinutes('Simmer for 3 to 5 minutes.'), 3);
      expect(extractMinutes('Fry for 8 to 10 mins.'), 8);
    });

    test('returns 0 when no time duration is present', () {
      expect(extractMinutes('Garnish with freshly chopped cilantro and serve.'), 0);
      expect(extractMinutes('Add salt and pepper to taste.'), 0);
    });
  });
}
