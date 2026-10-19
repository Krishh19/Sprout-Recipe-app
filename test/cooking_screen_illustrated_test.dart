import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/features/cooking/cooking_screen.dart';

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

  testWidgets('CookingScreen renders illustrated cookbook elements and expands instruction modal on tap', (tester) async {
    const testRecipe = Recipe(
      id: 'test-illustrated-1',
      title: 'Kara Boondi Kurma',
      description: 'Spicy kurma curry with crispy boondi',
      ingredients: ['Boondi', 'Onions', 'Tomatoes', 'Curry leaves'],
      cleanedIngredients: ['boondi', 'onions', 'tomatoes', 'curry leaves'],
      instructions: [
        'Sauté for about 30 seconds. Next, add onions and cook until soft and translucent.',
        'Add spices and simmer for 5 minutes.',
      ],
      totalTimeMins: 20,
      servings: 1,
      cuisine: 'South Indian',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CookingScreen(recipe: testRecipe),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify step counter
    expect(find.text('STEP 1 OF 2'), findsOneWidget);

    // Verify recipe badge
    expect(find.text('Kara Boondi Kurma'), findsOneWidget);

    // Verify bulky SUGGESTED TIMER box is removed completely
    expect(find.text('SUGGESTED TIMER'), findsNothing);
    expect(find.text('—  1 min'), findsNothing);
    expect(find.text('+  1 min'), findsNothing);

    // Verify Step At-a-Glance chips are rendered with ingredients extracted from step text
    expect(find.text('Onions'), findsOneWidget);

    // Verify 'Tap to expand' pill indicator is hidden when instruction fits within 3 lines
    expect(find.text('Tap to expand'), findsNothing);

    // Tap on the instruction card to open the expanded full modal
    final instructionFinder = find.textContaining('Sauté for about 30 seconds');
    expect(instructionFinder, findsOneWidget);
    await tester.tap(instructionFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify full expanded modal opened with STEP 1 DETAILS
    expect(find.text('STEP 1 DETAILS'), findsOneWidget);
    expect(find.text('Got It ✓'), findsOneWidget);

    // Dismiss the modal
    await tester.tap(find.text('Got It ✓'));
    await tester.pumpAndSettle();

    // Verify modal dismissed and back on main screen
    expect(find.text('STEP 1 DETAILS'), findsNothing);
    expect(find.text('Next Step →'), findsOneWidget);
  });

  testWidgets('CookingScreen displays full instruction text without premature 3-line clamping', (tester) async {
    // Set constrained mobile width (e.g. 360)
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const longRecipe = Recipe(
      id: 'test-long-1',
      title: 'Paneer Chilli Dosa',
      description: 'Fusion street-style dosa stuffed with chili paneer',
      ingredients: ['Dosa Batter', 'Paneer', 'Bell Pepper', 'Chilli Sauce'],
      cleanedIngredients: ['dosa batter', 'paneer', 'bell pepper', 'chilli sauce'],
      instructions: [
        'To begin making the Paneer Chilli Dosa Recipe, preheat a dosa tawa over medium heat for about two minutes until nicely hot, then spread a generous ladleful of fermented batter in swirling concentric circles from center outward, drizzle aromatic ghee around the perimeter, and wait for edges to lift crisp and golden brown.',
      ],
      totalTimeMins: 35,
      servings: 1,
      cuisine: 'Indo-Chinese',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CookingScreen(recipe: longRecipe),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Step At-a-Glance chips (Heat Level badge and ingredient chip)
    expect(find.text('🔥 Medium Flame'), findsOneWidget);
    expect(find.text('Dosa Batter'), findsOneWidget);

    // Verify full instruction text is rendered without premature truncation
    expect(find.textContaining('Preheat a dosa tawa over medium heat'), findsOneWidget);
    expect(find.textContaining('wait for edges to lift crisp and golden brown'), findsOneWidget);

    // Verify 'Tap to expand' pill is no longer needed since full text is displayed
    expect(find.text('Tap to expand'), findsNothing);
  });
}
