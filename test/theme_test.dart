import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sprout/design/colors.dart';
import 'package:sprout/design/components/sprout_button.dart';
import 'package:sprout/design/components/sprout_glass_nav.dart';
import 'package:sprout/design/components/sprout_metallic_text.dart';
import 'package:sprout/design/theme.dart';
import 'package:sprout/design/typography.dart';
import 'package:sprout/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    SproutColors.setDarkMode(false);
  });

  tearDown(() {
    SproutColors.setDarkMode(false);
  });

  group('Sprout Dark Mode & Colors Dynamic Resolution', () {
    test('resolves light mode tokens correctly by default', () {
      SproutColors.setDarkMode(false);
      expect(SproutColors.isDarkMode, isFalse);
      expect(SproutColors.canvas, equals(SproutColors.lightCanvas));
      expect(SproutColors.surface, equals(SproutColors.lightSurface));
      expect(SproutColors.primaryInk, equals(SproutColors.lightPrimaryInk));
      expect(SproutColors.secondaryInk, equals(SproutColors.lightSecondaryInk));
      expect(SproutColors.accent, equals(SproutColors.sproutGreen));
    });

    test('resolves dark mode tokens correctly when dark mode is enabled', () {
      SproutColors.setDarkMode(true);
      expect(SproutColors.isDarkMode, isTrue);
      expect(SproutColors.canvas, equals(SproutColors.nightCanvas));
      expect(SproutColors.surface, equals(SproutColors.nightSurface));
      expect(SproutColors.elevatedSurface, equals(SproutColors.nightElevatedSurface));
      expect(SproutColors.primaryInk, equals(SproutColors.nightPrimaryInk));
      expect(SproutColors.secondaryInk, equals(SproutColors.nightSecondaryInk));
      expect(SproutColors.accent, equals(SproutColors.nightAccent));
    });

    test('resolve() custom helper honors dark mode state', () {
      const lightCol = Color(0xFF112233);
      const darkCol = Color(0xFFAABBCC);

      SproutColors.setDarkMode(false);
      expect(SproutColors.resolve(lightCol, darkCol), equals(lightCol));

      SproutColors.setDarkMode(true);
      expect(SproutColors.resolve(lightCol, darkCol), equals(darkCol));
    });
  });

  group('SproutTheme Material 3 Configurations', () {
    test('lightTheme has Brightness.light and correct canvas color', () {
      final theme = SproutTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(SproutColors.lightCanvas));
      expect(theme.colorScheme.surface, equals(SproutColors.lightSurface));
    });

    test('darkTheme has Brightness.dark and correct canvas color', () {
      final theme = SproutTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(SproutColors.nightCanvas));
      expect(theme.colorScheme.surface, equals(SproutColors.nightSurface));
    });
  });

  group('ThemeModeNotifier & Persistence', () {
    test('defaults to ThemeMode.system when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });

    test('setThemeMode updates state and persists preference', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(SproutColors.isDarkMode, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sprout_theme_mode'), equals('dark'));

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(SproutColors.isDarkMode, isFalse);
      expect(prefs.getString('sprout_theme_mode'), equals('light'));
    });

    test('toggleDarkMode switches between dark and light', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(SproutColors.isDarkMode, isFalse);

      await notifier.toggleDarkMode();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(SproutColors.isDarkMode, isTrue);

      await notifier.toggleDarkMode();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(SproutColors.isDarkMode, isFalse);

      await notifier.toggleDarkMode();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(SproutColors.isDarkMode, isTrue);
    });

    test('loads saved preference from SharedPreferences on initialization', () async {
      SharedPreferences.setMockInitialValues({'sprout_theme_mode': 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger lazy build
      container.read(themeModeProvider);

      // Allow microtask to process
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(SproutColors.isDarkMode, isTrue);
    });
  });

  group('Riverpod themeModeProvider Integration', () {
    testWidgets('changing theme mode triggers reactive rebuild', (tester) async {
      final container = ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeModeProvider);
            return MaterialApp(
              themeMode: themeMode,
              theme: SproutTheme.lightTheme,
              darkTheme: SproutTheme.darkTheme,
              home: Scaffold(
                body: Text('CurrentMode: ${themeMode.name}'),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(container);
      expect(find.text('CurrentMode: system'), findsOneWidget);

      final element = tester.element(find.byType(Consumer));
      final containerRef = ProviderScope.containerOf(element);

      await containerRef.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(find.text('CurrentMode: dark'), findsOneWidget);
    });
  });

  group('Golden Metallic Heading Tests', () {
    test('goldGradient has defined colors and stops', () {
      expect(SproutColors.metallicGoldGradientColors.length, equals(5));
      expect(SproutColors.metallicGoldGradientStops.length, equals(5));
      expect(SproutColors.goldGradient.colors, equals(SproutColors.metallicGoldGradientColors));
    });

    testWidgets('SproutMetallicHeading renders plain text in light mode and ShaderMask in dark mode', (tester) async {
      // In Light Mode
      SproutColors.setDarkMode(false);
      await tester.pumpWidget(
        MaterialApp(
          theme: SproutTheme.lightTheme,
          home: Scaffold(
            body: SproutMetallicHeading(
              'What are we cooking today?',
              style: SproutTypography.h2(),
            ),
          ),
        ),
      );

      expect(find.text('What are we cooking today?'), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);

      // In Dark Mode
      SproutColors.setDarkMode(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: SproutTheme.darkTheme,
          home: Scaffold(
            body: SproutMetallicHeading(
              'What are we cooking today?',
              style: SproutTypography.h2(),
            ),
          ),
        ),
      );

      expect(find.text('What are we cooking today?'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('Bottom Navigation Bar Highlight Tests', () {
    testWidgets('active tab is highlighted without background box container', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // ignore: deprecated_member_use
          child: ShowCaseWidget(
            builder: (context) => MaterialApp(
              theme: SproutTheme.lightTheme,
              home: Scaffold(
                bottomNavigationBar: SproutGlassNav(
                  currentIndex: 0,
                  onIndexChanged: (_) {},
                  onScanTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify all tabs render without an opaque background box
      // Find the AnimatedContainers inside SproutGlassNav
      final navFinder = find.byType(SproutGlassNav);
      expect(navFinder, findsOneWidget);

      // Check AnimatedContainers for nav items: their color must be Colors.transparent
      final containers = tester.widgetList<AnimatedContainer>(
        find.descendant(of: navFinder, matching: find.byType(AnimatedContainer)),
      );

      // Look for the nav item containers (those with BoxConstraints minWidth: 54)
      final navItemContainers = containers.where((c) {
        final box = c.decoration is BoxDecoration ? c.decoration as BoxDecoration : null;
        return c.constraints?.minWidth == 54 && box != null;
      }).toList();

      expect(navItemContainers.length, equals(4)); // 4 items: Home, Explore, Saved, Profile
      for (final item in navItemContainers) {
        final box = item.decoration as BoxDecoration;
        expect(box.color, equals(Colors.transparent));
      }
    });
  });

  group('SproutButton Dark Mode Primary Variant', () {
    testWidgets('primary button has white text in dark mode', (tester) async {
      SproutColors.setDarkMode(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: SproutTheme.darkTheme,
          home: Scaffold(
            body: SproutButton(
              label: 'Start Cooking →',
              onPressed: () {},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Start Cooking →'));
      expect(textWidget.style?.color, equals(Colors.white));
    });
  });
}
