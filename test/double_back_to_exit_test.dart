import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/design/radii.dart';
import 'package:sprout/features/main_shell_screen.dart';
import 'package:sprout/features/search/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp({TargetPlatform platform = TargetPlatform.android, int initialIndex = 0}) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        home: MainShellScreen(initialIndex: initialIndex),
      ),
    );
  }

  group('MainShellScreen Double-Back-to-Exit Behavior', () {
    testWidgets('First Back press on home screen shows "Tap again to exit" snackbar and prevents exit', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue, reason: 'First Back press should be handled by PopScope');
      await tester.pump();

      // Verify the snackbar message
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      expect(find.text('Tap again to exit'), findsOneWidget);

      // Verify UI styling requirements
      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      expect(snackBar.backgroundColor, equals(const Color(0xEB262626)));
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(SproutRadii.card));
      expect(snackBar.duration, equals(const Duration(seconds: 2)));
    });

    testWidgets('Second Back press within 2 seconds exits the app', (tester) async {
      int systemPopCalls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        },
      );

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // First press
      final firstResult = await tester.binding.handlePopRoute();
      expect(firstResult, isTrue);
      await tester.pump();
      expect(find.text('Tap again to exit'), findsOneWidget);

      // Second press within 2 seconds
      final secondResult = await tester.binding.handlePopRoute();
      await tester.pump();

      // Normal app exit occurs (canPop was true, bubble to system) or SystemNavigator.pop called
      final appExited = !secondResult || systemPopCalls > 0;
      expect(appExited, isTrue, reason: 'Second back press within 2 seconds should allow app exit');
    });

    testWidgets('Back press after 2-second timeout resets state and shows warning again', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // First press
      final firstResult = await tester.binding.handlePopRoute();
      expect(firstResult, isTrue);
      await tester.pump();
      expect(find.text('Tap again to exit'), findsOneWidget);

      // Advance clock past 2-second timeout (e.g. 2100ms)
      await tester.pump(const Duration(milliseconds: 2100));

      // Press again after timeout - should show warning again and NOT exit
      final thirdResult = await tester.binding.handlePopRoute();
      expect(thirdResult, isTrue, reason: 'Back press after timeout must be caught again as first press');
      await tester.pump();
      expect(find.text('Tap again to exit'), findsOneWidget);
    });

    testWidgets('Back press on nested screen navigates back without showing double-back warning', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push a nested screen onto the Navigator stack
      final context = tester.element(find.byType(MainShellScreen));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Nested Screen')),
            body: const Center(child: Text('Nested Details')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nested Details'), findsOneWidget);

      // Press Back on nested screen
      final popResult = await tester.binding.handlePopRoute();
      expect(popResult, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should have returned to MainShellScreen, and "Tap again to exit" must NOT be shown
      expect(find.text('Nested Details'), findsNothing);
      expect(find.text('Tap again to exit'), findsNothing);
    });

    testWidgets('Back press with dialog open dismisses dialog without double-back warning', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open a dialog
      final context = tester.element(find.byType(MainShellScreen));
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Confirmation Dialog'),
          content: Text('Dialog content'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Confirmation Dialog'), findsOneWidget);

      // Press Back
      final popResult = await tester.binding.handlePopRoute();
      expect(popResult, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog is dismissed, no double-back warning
      expect(find.text('Confirmation Dialog'), findsNothing);
      expect(find.text('Tap again to exit'), findsNothing);
    });

    testWidgets('Back press on non-home bottom nav tab navigates to home tab without exit warning', (tester) async {
      // Start on Explore / Search tab (index 1)
      await tester.pumpWidget(buildApp(initialIndex: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial state has SearchScreen
      expect(find.byType(SearchScreen), findsOneWidget);

      // Press Back on tab 1
      final popResult = await tester.binding.handlePopRoute();
      expect(popResult, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigated to Home tab, no exit warning shown
      expect(find.text('What are we cooking today?'), findsOneWidget);
      expect(find.text('Tap again to exit'), findsNothing);

      // Subsequent Back press on Home tab now shows the exit warning
      final homePopResult = await tester.binding.handlePopRoute();
      expect(homePopResult, isTrue);
      await tester.pump();
      expect(find.text('Tap again to exit'), findsOneWidget);
    });

    testWidgets('iOS platform preserves default iOS back behavior (no double-back toast)', (tester) async {
      await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final popResult = await tester.binding.handlePopRoute();
      expect(popResult, isFalse, reason: 'iOS should allow normal pop/exit without double-back interception');
      expect(find.text('Tap again to exit'), findsNothing);
    });
  });
}
