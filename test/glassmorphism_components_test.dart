import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/glass.dart';
import 'package:sprout/models/meal_plan_item.dart';

void main() {
  group('SproutGlassCard Component Tests', () {
    testWidgets('SproutGlassCard renders child with gradient borders and shadows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassCard(
              blurSigma: 24.0,
              backgroundColor: SproutColors.glassSmokedDark,
              borderGradient: SproutColors.glassSpecularBorder,
              child: const Text('Frosted Content'),
            ),
          ),
        ),
      );

      expect(find.text('Frosted Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('SproutGlassCard responds to tap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SproutGlassCircleButton Component Tests', () {
    testWidgets('SproutGlassCircleButton renders circular glass button and triggers onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassCircleButton(
              iconData: Icons.close_rounded,
              tooltip: 'Close Button',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byType(SproutGlassCircleButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SproutGlassBadgePill Component Tests', () {
    testWidgets('SproutGlassBadgePill renders text and icon', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassBadgePill(
              text: 'Choose when to make it',
              icon: Icons.calendar_today_rounded,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Choose when to make it'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      await tester.tap(find.text('Choose when to make it'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SproutGlassStepper Component Tests', () {
    testWidgets('SproutGlassStepper increments and decrements within bounds', (tester) async {
      int currentVal = 4;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SproutGlassStepper(
                  value: currentVal,
                  min: 1,
                  max: 8,
                  onChanged: (v) => setState(() => currentVal = v),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);

      // Tap plus
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(currentVal, equals(5));
      expect(find.text('5'), findsOneWidget);

      // Tap minus
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(currentVal, equals(4));
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('SproutGlassDock Component Tests', () {
    testWidgets('SproutGlassDock renders 5 actions and responds to taps', (tester) async {
      bool savedTapped = false;
      bool instructionsTapped = false;
      bool planTapped = false;
      bool groceryTapped = false;
      bool favoriteTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassDock(
              isSaved: false,
              isFavorite: true,
              onSaveTap: () => savedTapped = true,
              onInstructionsTap: () => instructionsTapped = true,
              onPlanTap: () => planTapped = true,
              onGroceryTap: () => groceryTapped = true,
              onFavoriteTap: () => favoriteTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();
      expect(savedTapped, isTrue);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(planTapped, isTrue);

      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();
      expect(groceryTapped, isTrue);

      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();
      expect(instructionsTapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();
      expect(favoriteTapped, isTrue);
    });
  });

  group('SproutGlassSegmentedTrack Component Tests', () {
    testWidgets('SproutGlassSegmentedTrack selects meal type with warm amber highlight', (tester) async {
      MealType selected = MealType.dinner;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SproutGlassSegmentedTrack<MealType>(
                  items: MealType.values,
                  selectedItem: selected,
                  onSelected: (m) => setState(() => selected = m),
                  labelBuilder: (m) => m.label,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);

      await tester.tap(find.text('Breakfast'));
      await tester.pumpAndSettle();
      expect(selected, equals(MealType.breakfast));
    });
  });

  group('SproutGlassSearchBar Component Tests', () {
    testWidgets('SproutGlassSearchBar accepts input text', (tester) async {
      String text = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SproutGlassSearchBar(
              hintText: 'Search ingredients',
              onChanged: (val) => text = val,
            ),
          ),
        ),
      );

      expect(find.text('Search ingredients'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tofu');
      await tester.pumpAndSettle();
      expect(text, equals('Tofu'));
    });
  });
}
