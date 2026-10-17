import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/core/tutorial/sprout_coach_mark.dart';
import 'package:sprout/core/tutorial/tutorial_storage.dart';

void main() {
  group('TutorialStorage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state allows showing the main tour', () async {
      final storage = await TutorialStorage.create();
      expect(storage.isMainTourCompleted(), isFalse);
      expect(storage.isMainTourSkipped(), isFalse);
      expect(storage.shouldShowMainTour(), isTrue);
    });

    test('markMainTourCompleted updates persistence correctly', () async {
      final storage = await TutorialStorage.create();
      await storage.markMainTourCompleted();

      expect(storage.isMainTourCompleted(), isTrue);
      expect(storage.isMainTourSkipped(), isFalse);
      expect(storage.shouldShowMainTour(), isFalse);
    });

    test('markMainTourSkipped updates persistence correctly', () async {
      final storage = await TutorialStorage.create();
      await storage.markMainTourSkipped();

      expect(storage.isMainTourCompleted(), isFalse);
      expect(storage.isMainTourSkipped(), isTrue);
      expect(storage.shouldShowMainTour(), isFalse);
    });

    test('resetMainTour clears both completed and skipped flags', () async {
      final storage = await TutorialStorage.create();
      await storage.markMainTourCompleted();
      expect(storage.shouldShowMainTour(), isFalse);

      await storage.resetMainTour();
      expect(storage.isMainTourCompleted(), isFalse);
      expect(storage.isMainTourSkipped(), isFalse);
      expect(storage.shouldShowMainTour(), isTrue);
    });
  });

  group('SproutCoachMark Widget Tests', () {
    testWidgets('Renders step 1 correctly with Next and Skip actions', (tester) async {
      bool nextCalled = false;
      bool skipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SproutCoachMark(
                title: 'Food Scanner',
                description: 'Scan your groceries and ingredients.',
                stepIndex: 0,
                totalSteps: 5,
                onNext: () => nextCalled = true,
                onSkip: () => skipCalled = true,
                onDone: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Food Scanner'), findsOneWidget);
      expect(find.text('Scan your groceries and ingredients.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Back'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(nextCalled, isTrue);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipCalled, isTrue);
    });

    testWidgets('Renders intermediate step with Back button', (tester) async {
      bool backCalled = false;
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SproutCoachMark(
                title: 'Discover Recipes',
                description: 'Explore thousands of curated recipes.',
                stepIndex: 1,
                totalSteps: 5,
                onNext: () => nextCalled = true,
                onBack: () => backCalled = true,
                onSkip: () {},
                onDone: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Discover Recipes'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(backCalled, isTrue);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(nextCalled, isTrue);
    });

    testWidgets('Renders final step with Done button and mascot', (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SproutCoachMark(
                title: 'Profile & Preferences',
                description: 'Customize dietary preferences and explore tours.',
                stepIndex: 4,
                totalSteps: 5,
                onNext: () {},
                onBack: () {},
                onSkip: () {},
                onDone: () => doneCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Profile & Preferences'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Next'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(doneCalled, isTrue);
    });
  });
}
