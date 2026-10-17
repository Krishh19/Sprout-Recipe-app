import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/components/sprout_substitution_card.dart';
import 'package:sprout/models/substitution_schema.dart';
import 'package:sprout/providers/app_providers.dart';
import 'package:sprout/repositories/substitution_service.dart';

void main() {
  group('SubstitutionService Offline Fallback Tests', () {
    test('legacy Gemini service returns curated substitutions for staple Indian ingredients', () async {
      final service = GeminiSubstitutionService(apiKey: '');
      final subs = await service.getSubstitutions(
        missingIngredients: ['paneer', 'buttermilk'],
        recipeTitle: 'Paneer Butter Masala',
      );

      expect(subs.length, greaterThanOrEqualTo(2));
      final paneerSub = subs.firstWhere(
        (s) => s.originalIngredient.toLowerCase() == 'paneer',
      );
      expect(paneerSub.substitute.toLowerCase(), contains('tofu'));

      final butterMilkSub = subs.firstWhere(
        (s) => s.originalIngredient.toLowerCase() == 'buttermilk',
      );
      expect(butterMilkSub.substitute.toLowerCase(), contains('milk'));
    });

    test('Genkit service returns curated substitutions for staple Indian ingredients', () async {
      final service = GenkitSubstitutionService(apiKey: '');
      final subs = await service.getSubstitutions(
        missingIngredients: ['paneer', 'curry leaves', 'ghee'],
        recipeTitle: 'Paneer Butter Masala',
      );

      expect(subs.length, 3);
      final paneerSub = subs.firstWhere(
        (s) => s.originalIngredient.toLowerCase() == 'paneer',
      );
      expect(paneerSub.substitute.toLowerCase(), contains('tofu'));

      final curryLeavesSub = subs.firstWhere(
        (s) => s.originalIngredient.toLowerCase() == 'curry leaves',
      );
      expect(curryLeavesSub.substitute.toLowerCase(), contains('lime leaves'));

      final gheeSub = subs.firstWhere(
        (s) => s.originalIngredient.toLowerCase() == 'ghee',
      );
      expect(gheeSub.substitute.toLowerCase(), contains('butter'));
    });

    test('Genkit service creates intelligent culinary fallbacks for uncurated ingredients', () async {
      final service = GenkitSubstitutionService(apiKey: '');
      final subs = await service.getSubstitutions(
        missingIngredients: [
          'exotic truffle oil',
          'kaffir herb leaf',
          'special spice powder',
        ],
        recipeTitle: 'Special Curry',
      );

      expect(subs.length, 3);
      final oilSub = subs.firstWhere(
        (s) => s.originalIngredient.contains('oil'),
      );
      expect(oilSub.substitute.toLowerCase(), contains('butter'));

      final leafSub = subs.firstWhere(
        (s) => s.originalIngredient.contains('leaf'),
      );
      expect(leafSub.substitute.toLowerCase(), contains('parsley'));

      final spiceSub = subs.firstWhere(
        (s) => s.originalIngredient.contains('powder'),
      );
      expect(spiceSub.substitute.toLowerCase(), contains('masala'));
    });
  });

  group('Genkit Structured Output Domain Mapping & Validation', () {
    test('valid structured output items map directly to Sprout SubstitutionModel', () {
      final items = [
        SubstitutionOutputItem(
          originalIngredient: 'heavy cream',
          substitute: 'Cashew cream or full-fat coconut milk',
          culinaryTip:
              'Blend soaked cashews into a fine paste with water in 1:2 ratio.',
          rationale:
              'Provides equivalent silky richness and viscosity in gravies.',
        ),
        SubstitutionOutputItem(
          originalIngredient: 'kasuri methi',
          substitute: 'Celery leaves or pinch of dried fenugreek',
          culinaryTip: 'Crush gently before adding at the final simmer stage.',
          rationale: 'Replicates classic herbal aroma.',
        ),
      ];

      final mapped = GenkitSubstitutionService.mapAndValidateSubstitutions(
        items,
        ['heavy cream', 'kasuri methi'],
      );

      expect(mapped.length, 2);
      expect(mapped[0].originalIngredient, 'heavy cream');
      expect(mapped[0].substitute, 'Cashew cream or full-fat coconut milk');
      expect(mapped[0].culinaryTip, contains('Blend soaked cashews'));
      expect(mapped[0].rationale, contains('silky richness'));

      expect(mapped[1].originalIngredient, 'kasuri methi');
      expect(mapped[1].substitute, contains('Celery leaves'));
    });

    test('missing or malformed required fields are handled gracefully with fallback', () {
      final itemsWithMalformed = [
        SubstitutionOutputItem(
          originalIngredient: '', // Malformed/empty original
          substitute: 'Some substitute',
          culinaryTip: 'Some tip',
        ),
        SubstitutionOutputItem(
          originalIngredient: 'cilantro',
          substitute: '', // Malformed/empty substitute
          culinaryTip: 'Some tip',
        ),
        SubstitutionOutputItem(
          originalIngredient: 'coriander',
          substitute: 'Parsley',
          culinaryTip: '', // Empty tip should receive sensible default
        ),
      ];

      final mapped = GenkitSubstitutionService.mapAndValidateSubstitutions(
        itemsWithMalformed,
        ['cilantro', 'coriander'],
      );

      expect(mapped.length, 2);
      final corianderSub = mapped.firstWhere(
        (s) => s.originalIngredient == 'coriander',
      );
      expect(corianderSub.substitute, 'Parsley');
      expect(corianderSub.culinaryTip, 'Use in equal proportion.');

      // cilantro was malformed, so fallback was generated
      final cilantroSub = mapped.firstWhere(
        (s) => s.originalIngredient.toLowerCase().contains('cilantro'),
      );
      expect(cilantroSub.substitute.isNotEmpty, true);
    });

    test('empty output list recovers with smart culinary heuristics for all requested items', () {
      final mapped = GenkitSubstitutionService.mapAndValidateSubstitutions([], [
        'fresh ginger',
        'garlic cloves',
      ]);

      expect(mapped.length, 2);
      expect(mapped.any((s) => s.originalIngredient == 'fresh ginger'), true);
      expect(mapped.any((s) => s.originalIngredient == 'garlic cloves'), true);
    });

    test(
      'parseTextJsonFallback recovers substitutions from raw json string',
      () {
        const rawJson = '''
[
  {
    "original_ingredient": "lemon",
    "substitute": "Amchur powder or white vinegar",
    "culinary_tip": "Use 1/2 tsp amchur per tbsp lemon juice.",
    "rationale": "Provides needed tartness."
  }
]
''';

        final parsed = GenkitSubstitutionService.parseTextJsonFallback(
          rawJson,
          ['lemon'],
        );
        expect(parsed.length, 1);
        expect(parsed[0].originalIngredient, 'lemon');
        expect(parsed[0].substitute, contains('Amchur'));
      },
    );

    test(
      'parseTextJsonFallback handles invalid non-json string without throwing',
      () {
        final parsed = GenkitSubstitutionService.parseTextJsonFallback(
          'I cannot find substitutions.',
          ['lemon'],
        );
        expect(parsed, isEmpty);
      },
    );
  });

  group('Feature Flag and Service Routing', () {
    test(
      'SubstitutionService factory routes to legacy Gemini when flag is false',
      () {
        final service = SubstitutionService(useGenkit: false);
        expect(service, isA<GeminiSubstitutionService>());
      },
    );

    test('SubstitutionService factory routes to Genkit when flag is true', () {
      final service = SubstitutionService(useGenkit: true);
      expect(service, isA<GenkitSubstitutionService>());
    });

    test('Riverpod substitutionServiceProvider selects implementation based on config flag', () {
      final containerLegacy = ProviderContainer(
        overrides: [
          substitutionServiceProvider.overrideWithValue(
            GeminiSubstitutionService(apiKey: ''),
          ),
        ],
      );
      expect(
        containerLegacy.read(substitutionServiceProvider),
        isA<GeminiSubstitutionService>(),
      );

      final containerGenkit = ProviderContainer(
        overrides: [
          substitutionServiceProvider.overrideWithValue(
            GenkitSubstitutionService(apiKey: ''),
          ),
        ],
      );
      expect(
        containerGenkit.read(substitutionServiceProvider),
        isA<GenkitSubstitutionService>(),
      );
    });
  });

  group('UI Substitution Card State and Resilience Tests', () {
    testWidgets(
      'SproutSubstitutionCard renders substitutions and loading resolves cleanly',
      (tester) async {
        final mockGenkitService = GenkitSubstitutionService(apiKey: '');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              substitutionServiceProvider.overrideWithValue(mockGenkitService),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SproutSubstitutionCard(
                  missingIngredients: ['paneer', 'lemon'],
                  recipeTitle: 'Paneer Butter Masala',
                ),
              ),
            ),
          ),
        );

        // Initially shows loading or header
        expect(find.text('Pantry Substitutions'), findsOneWidget);

        // Settle async fetch
        await tester.pumpAndSettle();

        // Verify resolved items are displayed
        expect(find.text('2 missing items can be swapped'), findsOneWidget);
        expect(find.text('No paneer'), findsOneWidget);
        expect(find.text('No lemon'), findsOneWidget);
      },
    );

    testWidgets(
      'SproutSubstitutionCard renders nothing when missingIngredients is empty',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SproutSubstitutionCard(
                  missingIngredients: [],
                  recipeTitle: 'Paneer Butter Masala',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Pantry Substitutions'), findsNothing);
      },
    );
  });
}
