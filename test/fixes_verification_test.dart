import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprout/models/recipe.dart';
import 'package:sprout/repositories/substitution_service.dart';
import 'package:sprout/features/scanner/widgets/scanner_top_bar.dart';
import 'package:sprout/features/scanner/widgets/scanner_viewfinder.dart';
import 'package:sprout/features/scanner/widgets/scanned_ingredients_sheet.dart';
import 'package:sprout/features/profile/widgets/empty_states_gallery_screen.dart';
import 'package:sprout/features/profile/profile_screen.dart';
import 'package:sprout/features/recipes/recipe_detail_screen.dart';
import 'package:sprout/features/cooking/cooking_screen.dart';
import 'package:sprout/design/sprout_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 1: Default Servings Verification', () {
    test('Recipe model defaults servings to 1', () {
      const recipe = Recipe(
        id: 'r1',
        title: 'Dal Fry',
        description: 'Comfort food',
        ingredients: ['Dal', 'Ghee'],
        cleanedIngredients: ['dal', 'ghee'],
        instructions: ['Cook dal', 'Add tadka'],
        totalTimeMins: 20,
        cuisine: 'North Indian',
      );
      expect(recipe.servings, 1, reason: 'Default servings in constructor must be 1');
    });

    test('Recipe.fromJson normalizes servings to 1', () {
      final jsonWith4 = {
        'id': 'r2',
        'TranslatedRecipeName': 'Khichdi',
        'Cleaned-Ingredients': 'rice, dal',
        'TranslatedInstructions': 'Pressure cook together.',
        'TotalTimeInMins': 20,
        'Cuisine': 'Indian',
        'Servings': 4,
      };
      final recipe = Recipe.fromJson(jsonWith4);
      expect(recipe.servings, 1, reason: 'Legacy servings=4 in JSON must normalize to 1');

      final jsonWithoutServings = {
        'id': 'r3',
        'title': 'Poha',
        'cleaned_ingredients': ['poha', 'peanuts'],
        'instructions': ['Soak poha', 'Cook with spices'],
        'total_time_mins': 15,
        'cuisine': 'Indian',
      };
      final recipeWithout = Recipe.fromJson(jsonWithoutServings);
      expect(recipeWithout.servings, 1, reason: 'Omitted servings must default to 1');
    });
  });

  group('Issue 2: Pantry Substitutions Offline Fallback', () {
    final service = SubstitutionService();

    test('returns reliable substitutions for Indian pantry items', () async {
      final subs = await service.getSubstitutions(
        missingIngredients: ['coriander', 'dhania', 'sekta', 'curry leaves'],
        recipeTitle: 'Gujarati Sambharo',
      );

      expect(subs.isNotEmpty, isTrue);
      final corianderSub = subs.firstWhere((s) => s.originalIngredient.toLowerCase() == 'coriander');
      expect(corianderSub.substitute.isNotEmpty, isTrue);

      final dhaniaSub = subs.firstWhere((s) => s.originalIngredient.toLowerCase() == 'dhania');
      expect(dhaniaSub.substitute.isNotEmpty, isTrue);

      final sektaSub = subs.firstWhere((s) => s.originalIngredient.toLowerCase() == 'sekta');
      expect(sektaSub.substitute.toLowerCase(), contains('drumstick'));
    });

    test('unlisted missing ingredients receive smart fallback rather than empty list', () async {
      final subs = await service.getSubstitutions(
        missingIngredients: ['exotic truffle oil'],
        recipeTitle: 'Custom Gourmet Dish',
      );

      expect(subs.length, 1);
      expect(subs.first.originalIngredient, 'exotic truffle oil');
      expect(subs.first.substitute.isNotEmpty, isTrue);
    });
  });

  group('Issue 3: Scanner Header & Viewfinder Separation', () {
    testWidgets('ScannerTopBar displays sprout title without conflicting brand logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScannerTopBar(
              isAnalyzing: false,
            ),
          ),
        ),
      );

      // Verify 'sprout' title is present
      expect(find.text('sprout'), findsOneWidget);
      // Verify brand logo image is NOT in the ScannerTopBar
      expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == SproutAssets.brandLogo), findsNothing);
    });

    testWidgets('ScannerViewfinder is clean without conflicting buttons in its Stack', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScannerViewfinder(
              isAnalyzing: false,
            ),
          ),
        ),
      );

      // Camera & Upload buttons should NOT be inside the viewfinder stack
      expect(find.text('Take Photo'), findsNothing);
      expect(find.text('Upload Photo'), findsNothing);
    });
  });

  group('Issue 4: Scanned Ingredients Bottom Sheet', () {
    testWidgets('renders detected ingredients and handles toggling and confirmation', (tester) async {
      List<String>? confirmedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannedIngredientsSheet(
              initialIngredients: const ['tomato', 'onion', 'paneer'],
              onConfirm: (items) {
                confirmedItems = items;
              },
            ),
          ),
        ),
      );

      // Header verification
      expect(find.text('Sprout Spotted Items! ✨'), findsOneWidget);
      // Items rendered
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsOneWidget);
      expect(find.text('Paneer'), findsOneWidget);

      // Tap Confirm button
      final confirmBtn = find.text('Add 3 Items to Kitchen 🍳');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(confirmedItems, isNotNull);
      expect(confirmedItems!.length, 3);
      expect(confirmedItems, contains('tomato'));
      expect(confirmedItems, contains('onion'));
      expect(confirmedItems, contains('paneer'));
    });
  });

  group('Issue 6: Profile Screen Overflow & Empty States Gallery', () {
    testWidgets('ProfileScreen renders preferences without RenderFlex overflow', (tester) async {
      // Set constrained mobile width (e.g., 340px) to verify no overflow
      tester.view.physicalSize = const Size(340 * 3, 720 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Diet & Cooking Preferences header exists
      expect(find.text('Diet & Cooking Preferences'), findsOneWidget);
      // Verify Terms & Conditions menu item is present
      expect(find.text('Terms & Conditions'), findsOneWidget);
    });

    testWidgets('EmptyStatesGalleryScreen renders presets and switches view modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyStatesGalleryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Title
      expect(find.text('Empty States Gallery'), findsOneWidget);

      // First preset active: Saved Recipes
      expect(find.text('Saved Recipes (SavedScreen)'), findsWidgets);
      expect(find.text('No saved recipes yet'), findsOneWidget);

      // Tap action button in empty state
      final actionBtn = find.text('Explore Recipes').first;
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pump();

      // Verify snackbar feedback
      expect(find.textContaining('Action tapped: "Explore Recipes"'), findsOneWidget);

      // Switch to List View
      final toggleView = find.text('Single View');
      expect(toggleView, findsOneWidget);
      await tester.tap(toggleView);
      await tester.pumpAndSettle();

      expect(find.text('List View'), findsOneWidget);
      // Check multiple presets are rendered in list
      expect(find.text('No saved recipes yet'), findsOneWidget);
      expect(find.text('No collections yet'), findsOneWidget);
    });
  });

  group('RecipeDetailScreen Servings and Overflow Verification', () {
    testWidgets('renders 1 serving by default and does not overflow on 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const paneerRecipe = Recipe(
        id: 'fb-1',
        title: 'Paneer Butter Masala',
        description: 'Rich and creamy cottage cheese curry in tomato gravy',
        ingredients: ['Paneer 200g', 'Butter 2 tbsp', 'Tomatoes 3', 'Cream 2 tbsp'],
        cleanedIngredients: ['paneer', 'butter', 'tomatoes', 'cream'],
        instructions: ['Heat butter in a pan.', 'Add pureed tomatoes.', 'Simmer with spices.'],
        totalTimeMins: 30,
        servings: 1,
        diet: 'Vegetarian',
        cuisine: 'North Indian',
        rating: 4.9,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: paneerRecipe),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify 1 serving display
      expect(find.text('1 serving'), findsOneWidget);
      // Verify no exception / overflow
      expect(tester.takeException(), isNull);
    });
  });

  group('CookingScreen Timer Placement & Morphing Verification', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), (message) async => null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (message) async => 1);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('wakelock_plus'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    testWidgets('Step At-a-Glance chips are rendered and bulky timer is removed', (tester) async {
      const recipe = Recipe(
        id: 'test-cooking-1',
        title: 'Creamy Mushroom Pasta',
        description: 'Comforting pasta dish',
        ingredients: ['Pasta', 'Mushrooms', 'Garlic', 'Cream'],
        cleanedIngredients: ['pasta', 'mushrooms', 'garlic', 'cream'],
        instructions: [
          'Bring a large pot of salted water to a boil and cook pasta.',
          'In a skillet, sauté mushrooms in butter for 5 minutes until tender.',
          'Combine sauce and pasta together.',
        ],
        totalTimeMins: 20,
        servings: 1,
        cuisine: 'Italian',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: recipe),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bulky timer card is completely removed
      expect(find.text('SUGGESTED TIMER'), findsNothing);
      expect(find.text('Adjust time:'), findsNothing);
      expect(find.text('Pin to top'), findsNothing);

      // Step At-a-Glance chips display matched ingredients for Step 1
      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('Step ingredients are rendered without pill box containers and do not overflow on narrow screens', (tester) async {
      const recipe = Recipe(
        id: 'test-cooking-overflow',
        title: 'Mango Chunda',
        description: 'Pickle',
        ingredients: [
          '5 cups Mango (Raw) , peeled and grated (1 kg of peel and grated mango)',
          '2 tsp Salt',
        ],
        cleanedIngredients: [
          'mango',
          'salt',
        ],
        instructions: [
          'Peel the skin of the mangoes and then grate them. Combine the grated mangoes, salt and mix well.',
        ],
        totalTimeMins: 30,
        servings: 4,
        cuisine: 'Indian',
      );

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingScreen(recipe: recipe),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The long ingredient is rendered and does not throw any layout overflow errors
      expect(find.textContaining('5 cups Mango'), findsOneWidget);
      expect(find.textContaining('2 tsp Salt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
