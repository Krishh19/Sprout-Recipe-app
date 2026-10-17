import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/components/sprout_onboarding_hero.dart';
import 'package:sprout/design/theme.dart';
import 'package:sprout/features/onboarding/onboarding_screen.dart';
import 'package:sprout/providers/theme_provider.dart';
import 'package:variable_blur/variable_blur.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({required VoidCallback onComplete}) {
    return ProviderScope(
      child: MaterialApp(home: OnboardingScreen(onComplete: onComplete)),
    );
  }

  testWidgets('renders first slide with headline and Skip button', (
    tester,
  ) async {
    bool completed = false;
    await tester.pumpWidget(buildSubject(onComplete: () => completed = true));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('WELCOME TO SPROUT'), findsOneWidget);
    expect(
      find.text("Turn what's in your\nkitchen into dinner."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding_next_button')), findsOneWidget);

    // Tapping Skip completes onboarding and writes SharedPreferences
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sprout_has_completed_onboarding'), isTrue);
  });

  testWidgets(
    'navigates through slides with corner forward and back buttons and configures taste profile',
    (tester) async {
      bool completed = false;
      await tester.pumpWidget(buildSubject(onComplete: () => completed = true));
      await tester.pumpAndSettle();

      // Slide 1 -> 2
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('AI INGREDIENT SCANNER'), findsOneWidget);
      expect(
        find.text('Snap your ingredients.\nGet instant recipes.'),
        findsOneWidget,
      );

      // Back button is visible on slide 2
      expect(find.byKey(const Key('onboarding_back_button')), findsOneWidget);

      // Slide 2 -> 3
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('GUIDED COOKING'), findsOneWidget);
      expect(
        find.text('Cook with confidence\nat your own pace.'),
        findsOneWidget,
      );

      // Slide 3 -> 4 (Personalization)
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('TASTE PROFILE SETUP'), findsOneWidget);
      expect(find.text('Personalize your kitchen'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_next_button')), findsOneWidget);

      // Diet options (single select with No preference)
      expect(find.text('No preference'), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
      await tester.tap(find.text('Vegetarian'));
      await tester.pumpAndSettle();

      // Multi-select restriction
      expect(find.text('Gluten-Free'), findsOneWidget);
      await tester.ensureVisible(find.text('Gluten-Free'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gluten-Free'));
      await tester.pumpAndSettle();

      // Tap forward button on last slide to finish
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sprout_has_completed_onboarding'), isTrue);
      final savedPrefs = prefs.getStringList('sprout_user_preferences');
      expect(savedPrefs, contains('Vegetarian'));
      expect(savedPrefs, contains('Gluten-Free'));
    },
  );

  testWidgets(
    'OnboardingHero uses localized VariableBlur and seamless gradient ending in lightCanvas',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SproutTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingHero(
              imageAsset: 'assets/onboarding/welcome.png',
              backgroundColor: SproutColors.lightCanvas,
              height: 260,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingHero), findsOneWidget);
      expect(find.byType(VariableBlur), findsOneWidget);

      final blurWidget = tester.widget<VariableBlur>(find.byType(VariableBlur));
      expect(blurWidget.sigma, equals(12.0));
      expect(blurWidget.quality, equals(BlurQuality.medium));

      // Verify gradient ends in the exact light page background color
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OnboardingHero),
          matching: find.byType(DecoratedBox),
        ),
      );
      final gradientBox = decoratedBoxes.firstWhere(
        (b) => (b.decoration as BoxDecoration).gradient != null,
      );
      final gradient =
          (gradientBox.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.last, equals(SproutColors.lightCanvas));
      expect(
        gradient.colors.first,
        equals(SproutColors.lightCanvas.withValues(alpha: 0.0)),
      );
    },
  );

  testWidgets('OnboardingHero in dark mode ends in exact nightCanvas color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SproutTheme.darkTheme,
        home: const Scaffold(
          body: OnboardingHero(
            imageAsset: 'assets/onboarding/welcome.png',
            backgroundColor: SproutColors.nightCanvas,
            height: 260,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoratedBoxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(OnboardingHero),
        matching: find.byType(DecoratedBox),
      ),
    );
    final gradientBox = decoratedBoxes.firstWhere(
      (b) => (b.decoration as BoxDecoration).gradient != null,
    );
    final gradient =
        (gradientBox.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors.last, equals(SproutColors.nightCanvas));
    expect(
      gradient.colors.first,
      equals(SproutColors.nightCanvas.withValues(alpha: 0.0)),
    );
  });

  testWidgets(
    'OnboardingHero gradient-only fallback renders without VariableBlur when enableBlur is false',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SproutTheme.lightTheme,
          home: const Scaffold(
            body: OnboardingHero(
              imageAsset: 'assets/onboarding/welcome.png',
              backgroundColor: SproutColors.lightCanvas,
              height: 260,
              enableBlur: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingHero), findsOneWidget);
      expect(find.byType(VariableBlur), findsNothing);

      // Gradient overlay remains intact for smooth transition
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OnboardingHero),
          matching: find.byType(DecoratedBox),
        ),
      );
      final gradientBox = decoratedBoxes.firstWhere(
        (b) => (b.decoration as BoxDecoration).gradient != null,
      );
      final gradient =
          (gradientBox.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.last, equals(SproutColors.lightCanvas));
    },
  );

  testWidgets(
    'OnboardingScreen automatically updates hero gradient when theme changes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      Widget buildThemedApp() {
        return UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                themeMode: mode,
                theme: SproutTheme.lightTheme,
                darkTheme: SproutTheme.darkTheme,
                home: OnboardingScreen(onComplete: () {}),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildThemedApp());
      await tester.pumpAndSettle();

      // In light theme, hero gradient ends in lightCanvas
      var decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OnboardingHero),
          matching: find.byType(DecoratedBox),
        ),
      );
      var gradientBox = decoratedBoxes.firstWhere(
        (b) => (b.decoration as BoxDecoration).gradient != null,
      );
      var gradient =
          (gradientBox.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.last, equals(SproutColors.lightCanvas));

      // Switch to dark mode
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      // Hero gradient automatically updates to exact dark canvas
      decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OnboardingHero),
          matching: find.byType(DecoratedBox),
        ),
      );
      gradientBox = decoratedBoxes.firstWhere(
        (b) => (b.decoration as BoxDecoration).gradient != null,
      );
      gradient =
          (gradientBox.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.last, equals(SproutColors.nightCanvas));
    },
  );
}
