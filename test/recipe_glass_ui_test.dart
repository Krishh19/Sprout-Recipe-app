import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/design/glass.dart';
import 'package:sprout/features/recipes/recipe_detail_screen.dart';
import 'package:sprout/features/recipes/widgets/add_to_grocery_glass_sheet.dart';
import 'package:sprout/features/recipes/widgets/add_to_plan_glass_sheet.dart';
import 'package:sprout/models/recipe.dart';

const testRecipe = Recipe(
  id: 'air_fryer_tofu',
  title: 'Air Fryer Tofu',
  description: 'Crispy jagged seasoned chunks.',
  cuisine: 'Asian American Fusion',
  diet: 'veg',
  totalTimeMins: 25,
  servings: 4,
  ingredients: [
    '1 block Extra Firm Tofu',
    '1/2 tsp Garlic Powder',
    '2 tbsp Nutritional Yeast',
    '3/4 tsp Smoked Paprika',
  ],
  cleanedIngredients: [
    'tofu',
    'garlic powder',
    'nutritional yeast',
    'smoked paprika',
  ],
  instructions: [
    'Cut tofu into bite-sized jagged pieces.',
    'Toss with olive oil, garlic powder, and paprika.',
    'Air fry at 400F for 15 minutes shaking halfway.',
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecipeDetailScreen Glassmorphic UI Tests', () {
    testWidgets('Renders glass top navigation, status badge, metric chips, and floating dock', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: testRecipe),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Glass Navigation
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Choose when to make it'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // Recipe Header & Description
      expect(find.text('Air Fryer Tofu'), findsOneWidget);
      expect(find.text('Crispy jagged seasoned chunks.'), findsOneWidget);

      // Glass Metric Chips & Stepper
      expect(find.text('PREP'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('COOK'), findsOneWidget);
      expect(find.text('25 min'), findsAtLeast(1));
      expect(find.text('SERVES'), findsOneWidget);
      expect(find.byType(SproutGlassStepper), findsOneWidget);

      // Warm Cream "Start Cooking" Pill Button
      expect(find.text('Start Cooking →'), findsOneWidget);

      // Floating Glass Bottom Dock
      expect(find.byType(SproutGlassDock), findsOneWidget);
    });

    testWidgets('Tapping Plan icon on dock opens AddToPlanGlassSheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: testRecipe),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the calendar/plan icon in the floating glass dock specifically
      final planIcon = find.descendant(
        of: find.byType(SproutGlassDock),
        matching: find.byIcon(Icons.calendar_month_outlined),
      );
      expect(planIcon, findsOneWidget);

      await tester.tap(planIcon);
      await tester.pumpAndSettle();

      // Verify Add to Plan modal bottom sheet opens
      expect(find.text('Add to Plan'), findsOneWidget);
      expect(find.text('When'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Save to Meal Plan'), findsOneWidget);
    });

    testWidgets('Tapping Grocery icon on dock opens AddToGroceryGlassSheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: testRecipe),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap shopping bag/cart icon in the floating glass dock
      final cartIcon = find.byIcon(Icons.shopping_bag_outlined);
      expect(cartIcon, findsOneWidget);

      await tester.tap(cartIcon);
      await tester.pumpAndSettle();

      // Verify Add to Grocery modal bottom sheet opens
      expect(find.text('Add to Grocery'), findsOneWidget);
      expect(find.byType(SproutGlassSearchBar), findsOneWidget);
      expect(find.text('Search ingredients'), findsOneWidget);
      expect(find.textContaining('To buy'), findsOneWidget);
    });
  });

  group('Glass Sheets Standalone Tests', () {
    testWidgets('AddToPlanGlassSheet renders date pill and changes meal selection', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddToPlanGlassSheet(recipe: testRecipe, initialServings: 4),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add to Plan'), findsOneWidget);
      expect(find.text('4 servings'), findsOneWidget);

      // Switch to Lunch
      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
    });

    testWidgets('AddToGroceryGlassSheet filters ingredients on search input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddToGroceryGlassSheet(recipe: testRecipe, servings: 4),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add to Grocery'), findsOneWidget);
      expect(find.text('Garlic'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Nutritional');
      await tester.pumpAndSettle();

      expect(find.text('Nutritional Yeast'), findsOneWidget);
      expect(find.text('Garlic'), findsNothing);
    });
  });
}
