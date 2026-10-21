import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/home/widgets/sprout_weekly_planner_card.dart';
import 'package:sprout/features/main_shell_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SproutWeeklyPlannerCard & HomeScreen Dual Cards', () {
    testWidgets('SproutWeeklyPlannerCard renders clean heading and Sprout mascot',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SproutWeeklyPlannerCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Heading only - subtext and extra CTA button removed for compact layout
      expect(find.text('Plan your week'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Plan your week',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping SproutWeeklyPlannerCard triggers custom callback if provided',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SproutWeeklyPlannerCard(
                onCustomTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Plan your week'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('HomeScreen renders both Scan your ingredients and Plan your week cards side-by-side without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Scan your ingredients'), findsOneWidget);
      expect(find.text('Plan your week'), findsOneWidget);
      expect(find.byType(SproutWeeklyPlannerCard), findsOneWidget);
    });
  });
}
