import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import '../core/tutorial/tutorial_manager.dart';
import '../design/colors.dart';
import '../design/components/sprout_glass_nav.dart';
import '../design/motion.dart';
import '../providers/theme_provider.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'saved/saved_screen.dart';
import 'scanner/scanner_screen.dart';
import 'search/search_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  String? _pendingSearchQuery;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fadeController = AnimationController(
      vsync: this,
      duration: SproutMotion.fast,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: SproutMotion.emphasized,
    );

    ShowcaseView.register(
      disableBarrierInteraction: true,
      overlayOpacity: 0.58,
      onFinish: () {
        ref.read(tutorialManagerProvider).onTourFinished();
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onIndexChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _isNavVisible = true;
    });
    _fadeController.forward(from: 0.0);
  }

  void _handleSearchTrigger(String query) {
    setState(() {
      _pendingSearchQuery = query;
      _currentIndex = 1; // Explore / Search tab
      _isNavVisible = true;
    });
    _fadeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Watch themeMode to synchronize theme transitions instantly across all shell components
    final themeMode = ref.watch(themeModeProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);
    SproutColors.setDarkMode(isDark);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? SproutColors.nightSkyBackgroundGradient
            : SproutColors.lightSkyBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Let content scroll beneath the translucent glass nav bar and behind status bar
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis != Axis.vertical) return false;

            // Always ensure nav bar is visible when near the very top of content
            if (notification.metrics.pixels <= 24) {
              if (!_isNavVisible) {
                setState(() => _isNavVisible = true);
              }
              return false;
            }

            if (notification.direction == ScrollDirection.reverse && _isNavVisible) {
              // Scrolling down into content -> hide bottom nav
              setState(() => _isNavVisible = false);
            } else if (notification.direction == ScrollDirection.forward && !_isNavVisible) {
              // Scrolling up towards top -> reveal bottom nav
              setState(() => _isNavVisible = true);
            }
            return false;
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onSearchTriggered: _handleSearchTrigger,
                  onExploreTriggered: () => _onIndexChanged(1),
                  onScanTriggered: () => _onIndexChanged(2),
                ),
                SearchScreen(initialQuery: _pendingSearchQuery),
                const ScannerScreen(),
                SavedScreen(onExploreTap: () => _onIndexChanged(1)),
                ProfileScreen(onTabSwitch: _onIndexChanged),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedSlide(
          offset: _isNavVisible ? Offset.zero : const Offset(0, 1.4),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          child: SproutGlassNav(
            currentIndex: _currentIndex,
            onIndexChanged: _onIndexChanged,
            onScanTap: () => _onIndexChanged(2),
          ),
        ),
      ),
    );
  }
}

