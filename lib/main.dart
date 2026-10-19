import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:variable_blur/variable_blur.dart';

import 'core/supabase_client.dart';
import 'core/tutorial/tutorial_manager.dart';
import 'core/tutorial/tutorial_storage.dart';
import 'design/colors.dart';
import 'design/theme.dart';
import 'features/main_shell_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modern edge-to-edge system UI styling (Android 14/15/16 & iOS)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Run initial services concurrently for lightning-fast cold boot
  final initResults = await Future.wait([
    SupabaseService.initialize(),
    SharedPreferences.getInstance(),
    VariableBlur.precacheShaders().catchError((_) {}),
  ]);

  // Non-blocking background anonymous authentication to prevent UI thread block
  unawaited(SupabaseService.signInAnonymouslyIfNeeded());

  final prefs = initResults[1] as SharedPreferences;
  final hasCompletedOnboarding =
      prefs.getBool('sprout_has_completed_onboarding') ?? false;

  // Hydrate saved theme mode before first frame to prevent theme flicker
  final savedTheme = prefs.getString(ThemeModeNotifier.keyThemeMode);
  if (savedTheme == 'dark') {
    SproutColors.setDarkMode(true);
  } else if (savedTheme == 'light') {
    SproutColors.setDarkMode(false);
  } else {
    final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    SproutColors.setDarkMode(platformDark);
  }

  final tutorialStorage = TutorialStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [tutorialStorageProvider.overrideWithValue(tutorialStorage)],
      child: SproutApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

class SproutApp extends ConsumerStatefulWidget {
  final bool hasCompletedOnboarding;

  const SproutApp({super.key, required this.hasCompletedOnboarding});

  @override
  ConsumerState<SproutApp> createState() => _SproutAppState();
}

class _SproutAppState extends ConsumerState<SproutApp> {
  late bool _showMainApp;

  @override
  void initState() {
    super.initState();
    _showMainApp = widget.hasCompletedOnboarding;
  }

  void _onOnboardingComplete() {
    setState(() {
      _showMainApp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sprout',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: SproutTheme.lightTheme,
      darkTheme: SproutTheme.darkTheme,
      builder: (context, child) {
        // Keep SproutColors dynamically synchronized with the resolved brightness
        final themeMode = ref.watch(themeModeProvider);
        final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system && platformDark);
        SproutColors.setDarkMode(isDark);

        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        );

        SystemChrome.setSystemUIOverlayStyle(overlayStyle);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child!,
        );
      },
      home: _showMainApp
          ? const MainShellScreen()
          : OnboardingScreen(onComplete: _onOnboardingComplete),
    );
  }
}
