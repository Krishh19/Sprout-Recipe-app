import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/cooking/cooking_screen.dart';
import 'package:sprout/features/recipes/recipe_detail_screen.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/services/recipe_translation_service.dart';
import 'package:sprout/services/gemini_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), (message) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), null);
  });

  group('RecipeTranslationService Unit Tests', () {
    test('isHindi detects Devanagari Hindi text accurately', () {
      expect(RecipeTranslationService.isHindi('मशरूम पसंदा रेसिपी'), isTrue);
      expect(RecipeTranslationService.isHindi('अब एक कढ़ाई में तेल गरम करें'), isTrue);
      expect(RecipeTranslationService.isHindi('Paneer Chilli Dosa'), isFalse);
      expect(RecipeTranslationService.isHindi('Preheat a tawa over medium flame'), isFalse);
      expect(RecipeTranslationService.isHindi(''), isFalse);
      expect(RecipeTranslationService.isHindi(null), isFalse);
    });

    test('isRecipeHindi detects Hindi recipes by title, instruction, or description', () {
      const hindiRecipe = Recipe(
        id: 'hi-1',
        title: 'मशरूम पसंदा',
        description: 'स्वादिष्ट मशरूम करी',
        ingredients: ['मशरूम', 'प्याज़', 'टमाटर'],
        cleanedIngredients: ['मशरूम', 'प्याज़', 'टमाटर'],
        instructions: ['अब एक कढ़ाई में तेल गरम करें'],
        totalTimeMins: 25,
        cuisine: 'Indian',
      );

      const englishRecipe = Recipe(
        id: 'en-1',
        title: 'Paneer Butter Masala',
        description: 'Rich Indian curry',
        ingredients: ['Paneer', 'Butter', 'Cream'],
        cleanedIngredients: ['paneer', 'butter', 'cream'],
        instructions: ['Heat butter in a pan over medium flame'],
        totalTimeMins: 30,
        cuisine: 'Indian',
      );

      expect(RecipeTranslationService.isRecipeHindi(hindiRecipe), isTrue);
      expect(RecipeTranslationService.isRecipeHindi(englishRecipe), isFalse);
    });

    test('extractBilingualEnglishTitle extracts English title from bilingual strings', () {
      expect(
        RecipeTranslationService.extractBilingualEnglishTitle('मशरूम पसंदा रेसिपी - Mushroom Pasanda'),
        equals('Mushroom Pasanda'),
      );
      expect(
        RecipeTranslationService.extractBilingualEnglishTitle('दाल मखनी (Dal Makhani)'),
        equals('Dal Makhani'),
      );
    });

    test('getHindiActionTitle extracts clean 3-4 word culinary actions without truncated filler', () {
      expect(
        RecipeTranslationService.getHindiActionTitle('मशरूम पसंदा बनाने के लिए सबसे पहले एक कढ़ाई में तेल गरम करें'),
        equals('कढ़ाई में तेल गरम करें'),
      );
      expect(
        RecipeTranslationService.getHindiActionTitle('तवा गरम करें और उस पर थोड़ा घी डालें'),
        equals('तवा गरम करें'),
      );
      expect(
        RecipeTranslationService.getHindiActionTitle('मसाला धीमी आंच पर भूनें'),
        equals('मसाला भूनें'),
      );
      expect(
        RecipeTranslationService.getHindiActionTitle('धीमी आंच पर 5 मिनट तक पकाएं'),
        equals('धीमी आंच पर पकाएं'),
      );
    });

    test('extractHindiDurationSeconds extracts minutes, seconds, hours, and cookware preheat', () {
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('5 मिनट तक धीमी आंच पर पकाएं'),
        equals(300),
      );
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('10 से 15 मिनट भूनें'),
        equals(600),
      );
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('30 सेकंड तक चलाएं'),
        equals(30),
      );
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('1 घंटा ढककर रखें'),
        equals(3600),
      );
      // Smart cookware preheating detection for "कढ़ाई में तेल गरम करें" -> 120s (02:00)
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('अब एक कढ़ाई में तेल गरम करें'),
        equals(120),
      );
      expect(
        RecipeTranslationService.extractHindiDurationSeconds('तवा गरम करें'),
        equals(120),
      );
    });
  });

  group('GeminiTtsService formatCookingText Tests', () {
    test('formatCookingText formats English steps correctly with Step prefix and pauses', () {
      final formatted = GeminiTtsService.formatCookingText('Preheat tawa. Sauté onions; then add spices.', 1, isHindi: false);
      expect(formatted, contains('Step 1. <short pause>'));
      expect(formatted, contains('Preheat tawa. <short pause>'));
      expect(formatted, contains('Sauté onions; <short pause>'));
    });

    test('formatCookingText formats Hindi steps correctly with चरण prefix and danda pauses', () {
      final formatted = GeminiTtsService.formatCookingText('कढ़ाई में तेल गरम करें। मसाला भूनें; फिर नमक डालें।', 1, isHindi: true);
      expect(formatted, contains('चरण 1. <short pause>'));
      expect(formatted, contains('कढ़ाई में तेल गरम करें. <short pause>'));
      expect(formatted, contains('मसाला भूनें; <short pause>'));
    });
  });

  group('CookingScreen & RecipeDetailScreen Bilingual UI Tests', () {
    const hindiRecipe = Recipe(
      id: 'hi-ui-1',
      title: 'मशरूम पसंदा रेसिपी',
      description: 'स्वादिष्ट मशरूम करी',
      ingredients: ['मशरूम', 'प्याज़', 'टमाटर'],
      cleanedIngredients: ['मशरूम', 'प्याज़', 'टमाटर'],
      instructions: ['अब एक कढ़ाई में तेल गरम करें'],
      totalTimeMins: 25,
      cuisine: 'North Indian',
    );

    const englishRecipe = Recipe(
      id: 'en-ui-1',
      title: 'Paneer Chilli Dosa',
      description: 'Crisp dosa with paneer',
      ingredients: ['Dosa batter', 'Paneer', 'Chilli'],
      cleanedIngredients: ['dosa batter', 'paneer', 'chilli'],
      instructions: ['Preheat a dosa tawa over medium flame'],
      totalTimeMins: 30,
      cuisine: 'South Indian',
    );

    testWidgets('CookingScreen displays HI badge and Hindi action title for Hindi recipe', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: hindiRecipe),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HI'), findsOneWidget);
      expect(find.text('कढ़ाई में तेल गरम करें'), findsOneWidget);
      expect(find.text('पकाना पूरा हुआ ✓'), findsOneWidget);
    });

    testWidgets('CookingScreen displays EN badge and English action title for English recipe', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: englishRecipe),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('EN'), findsOneWidget);
      expect(find.text('Preheat the Tawa'), findsOneWidget);
      expect(find.text('🔥 Medium Flame'), findsOneWidget);
      expect(find.text('पकाना पूरा हुआ ✓'), findsNothing);
      expect(find.text('Complete Recipe ✓'), findsOneWidget);
    });

    testWidgets('RecipeDetailScreen displays language pill and translated Start Cooking button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: hindiRecipe),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HI'), findsOneWidget);
      expect(find.text('पकाना शुरू करें →'), findsOneWidget);
    });
  });
}
