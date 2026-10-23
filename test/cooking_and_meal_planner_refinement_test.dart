import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/features/cooking/cooking_screen.dart';
import 'package:sprout/features/planner/meal_planner_screen.dart';
import 'package:sprout/models/meal_plan_item.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/providers/app_providers.dart';
import 'package:sprout/repositories/meal_plan_repository.dart';

class MockMealPlanRepository extends MealPlanRepository {
  final List<MealPlanItem> items;
  MockMealPlanRepository(this.items);

  @override
  Future<List<MealPlanItem>> fetchMealPlan() async => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), (message) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (message) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('speech_to_text'), (message) async => true);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('speech_to_text'), null);
  });

  const testRecipe = Recipe(
    id: 'test-recipe-refine',
    title: 'Spiced Chickpea Curry',
    description: 'Hearty protein curry',
    ingredients: ['Chickpeas', 'Onions', 'Tomatoes', 'Garam Masala'],
    cleanedIngredients: ['chickpeas', 'onions', 'tomatoes', 'garam masala'],
    instructions: [
      'Heat oil in a heavy-bottomed pot and sauté onions until golden brown.',
      'Add tomatoes, spices, and chickpeas. Simmer for 15 minutes.',
    ],
    totalTimeMins: 25,
    servings: 2,
    cuisine: 'Indian',
  );

  group('Cooking Mode Simplification Tests', () {
    testWidgets('Renders single Ask Sprout button with mic icon and NO recitation buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: testRecipe),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify single Ask Sprout button exists with microphone icon
      expect(find.text('Ask Sprout'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // 2. Verify recipe recitation button is completely absent from instruction card
      expect(find.byTooltip('Read step aloud'), findsNothing);
      expect(find.byTooltip('Stop narration'), findsNothing);
      expect(find.byTooltip('Loading voice...'), findsNothing);

      // 3. Verify recipe instructions and ingredient chips remain visible
      expect(find.textContaining('Heat oil in a heavy-bottomed pot'), findsOneWidget);
      expect(find.text('Onions'), findsOneWidget);

      // 4. Verify expanded instruction modal has NO "Read Aloud" button
      await tester.tap(find.textContaining('Heat oil in a heavy-bottomed pot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('STEP 1 DETAILS'), findsOneWidget);
      expect(find.text('Read Aloud'), findsNothing);
      expect(find.text('Pause Voice'), findsNothing);
      expect(find.text('Got It ✓'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Got It ✓'));
      await tester.pumpAndSettle();

      // 5. Verify Next Step navigation still functions
      expect(find.text('Next Step →'), findsOneWidget);
    });

    testWidgets('Tapping Ask Sprout triggers voice session and compact status indicator', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: testRecipe),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initially compact voice status close tooltip is hidden
      expect(find.byTooltip('Close'), findsNothing);

      // Tap Ask Sprout button to toggle voice session ON
      await tester.tap(find.text('Ask Sprout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Compact status indicator appears (e.g. Connecting / Listening)
      expect(find.byTooltip('Close'), findsOneWidget);

      // Instructions remain 100% visible while voice is active
      expect(find.textContaining('Heat oil in a heavy-bottomed pot'), findsOneWidget);

      // Tap close button on the compact indicator to release resources
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Compact indicator is dismissed
      expect(find.byTooltip('Close'), findsNothing);
    });
  });

  group('Meal Planner Calendar Redesign Tests', () {
    testWidgets('Renders compact horizontal 7-day strip with weekday labels ABOVE dates', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MealPlannerScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify uppercase weekday labels exist above dates
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);
      expect(find.text('THU'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);
      expect(find.text('SAT'), findsOneWidget);
      expect(find.text('SUN'), findsOneWidget);

      // 2. Verify Month range header is present (e.g. OCTOBER 2026)
      final now = DateTime.now();
      expect(find.textContaining('${now.year}'), findsWidgets);

      // 3. Verify 'Today' shortcut button is present
      expect(find.text('Today'), findsOneWidget);

      // 4. Verify day selection updates menu header
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final currentWeekday = now.weekday;
      expect(find.text('${dayNames[currentWeekday - 1]} Menu 🗓️'), findsOneWidget);

      // Tap another weekday (e.g., if today is Monday tap Tuesday, else tap Monday)
      final targetDayIndex = currentWeekday == 1 ? 2 : 1;
      final targetShort = targetDayIndex == 1 ? 'MON' : 'TUE';
      await tester.tap(find.text(targetShort));
      await tester.pumpAndSettle();

      // Verify selected day synchronized with menu
      expect(find.text('${dayNames[targetDayIndex - 1]} Menu 🗓️'), findsOneWidget);

      // Tap Today button to jump back
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('${dayNames[currentWeekday - 1]} Menu 🗓️'), findsOneWidget);
    });

    testWidgets('Meal Planner displays planned meal indicators and preserves grocery export', (tester) async {
      final mockRepo = MockMealPlanRepository([
        MealPlanItem(
          id: 'test-item-1',
          dayOfWeek: DateTime.now().weekday,
          mealType: MealType.breakfast,
          recipe: testRecipe,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealPlanRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MealPlannerScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify planned meal card is rendered for today
      expect(find.text('Spiced Chickpea Curry'), findsOneWidget);
      expect(find.text('Add to Groceries'), findsOneWidget);
    });
  });
}
