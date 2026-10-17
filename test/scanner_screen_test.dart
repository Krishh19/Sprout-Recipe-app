import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/main_shell_screen.dart';
import 'package:sprout/features/scanner/scanner_screen.dart';

void main() {
  testWidgets('ScannerScreen mounts and renders without errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ScannerScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('How it works?'), findsOneWidget);
  });

  testWidgets('MainShellScreen switches to ScannerScreen without element lifecycle error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainShellScreen(initialIndex: 0),
        ),
      ),
    );

    await tester.pump();

    // Tap center scan button
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('How it works?'), findsOneWidget);
  });

  testWidgets('ScannerHeroHeader displays exact 2-line headline, mascot, and callout in idle state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400); // ~412x915 dp
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ScannerScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('What\'s in your'), findsOneWidget);
    expect(find.text('kitchen today?'), findsOneWidget);
    expect(find.text('Scan\nCook\nEnjoy'), findsOneWidget);
    expect(find.textContaining('Take a photo or add ingredients'), findsOneWidget);
  });
}

