import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/components/sprout_button.dart';
import 'package:sprout/design/components/sprout_ingredient_chip.dart';
import 'package:sprout/features/main_shell_screen.dart';

void main() {
  group('Sprout Design System Component Tests', () {
    testWidgets('SproutButton renders label and triggers callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutButton(
              label: 'Start Cooking →',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Start Cooking →'), findsOneWidget);

      await tester.tap(find.text('Start Cooking →'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('SproutIngredientChip renders text and triggers delete', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutIngredientChip(
              label: 'Paneer',
              onDeleted: () {
                deleted = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Paneer'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(deleted, true);
    });

    test('Sprout color tokens match design system hex values', () {
      expect(SproutColors.canvas, const Color(0xFFF0F6FA));
      expect(SproutColors.surface, const Color(0xFFFFFFFF));
      expect(SproutColors.sproutGreen, const Color(0xFF214B38));
      expect(SproutColors.primaryInk, const Color(0xFF13362B));
    });

    testWidgets('HomeScreen renders clean UTF-8 greeting and wave mascot', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the mascot wave image
      final imageFinder = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('sprout_wave'),
      );
      expect(imageFinder, findsOneWidget);

      // Verify greeting text contains waving hand emoji and no mojibake
      final greetingFinder = find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('👋') ?? false),
      );
      expect(greetingFinder, findsOneWidget);

      // Verify no mojibake string is rendered anywhere
      expect(find.textContaining('\u00f0\u0178'), findsNothing);
      expect(find.textContaining('\u00e2'), findsNothing);
    });
  });
}
