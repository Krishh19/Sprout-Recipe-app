import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/components/sprout_shimmer.dart';

void main() {
  group('UI Enhancement Tests', () {
    test('SproutColors night kitchen tokens are defined with high contrast', () {
      expect(SproutColors.nightCanvas, const Color(0xFF080E12));
      expect(SproutColors.nightSurface, const Color(0xFF121E23));
      expect(SproutColors.nightPrimaryInk, const Color(0xFFF0FDF8));
      expect(SproutColors.nightAccent, const Color(0xFF4ADE80));
    });

    testWidgets('SproutRecipeCardSkeleton renders smoothly without layout errors',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SproutRecipeCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(SproutRecipeCardSkeleton), findsOneWidget);
    });

    testWidgets('SproutRecipeRowSkeleton renders smoothly without layout errors',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SproutRecipeRowSkeleton(),
          ),
        ),
      );

      expect(find.byType(SproutRecipeRowSkeleton), findsOneWidget);
    });
  });
}
