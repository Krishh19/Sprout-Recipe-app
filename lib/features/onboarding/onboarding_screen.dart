import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_filter_chip.dart';
import '../../design/components/sprout_metallic_text.dart';
import '../../design/components/sprout_onboarding_hero.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/motion.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';
import '../../providers/app_providers.dart';

import 'package:variable_blur/variable_blur.dart';

class _FeatureItem {
  final IconData icon;
  final Color tintColor;
  final String title;

  const _FeatureItem({
    required this.icon,
    required this.tintColor,
    required this.title,
  });
}

class _OnboardingSlideData {
  final String imageAsset;
  final String badgeText;
  final IconData badgeIcon;
  final String headline;
  final String bodyText;
  final List<_FeatureItem> features;

  const _OnboardingSlideData({
    required this.imageAsset,
    required this.badgeText,
    required this.badgeIcon,
    required this.headline,
    required this.bodyText,
    required this.features,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Diet options for single-select enforcement
  static const List<String> _dietOptions = [
    'Vegetarian',
    'Vegan',
    'Eggitarian',
    'Non-veg',
  ];

  late final List<_OnboardingSlideData> _slides = [
    const _OnboardingSlideData(
      imageAsset: SproutAssets.onboardingWelcome,
      badgeText: 'WELCOME TO SPROUT',
      badgeIcon: Icons.spa_rounded,
      headline: "Turn what's in your\nkitchen into dinner.",
      bodyText: 'No grocery runs needed. Sprout crafts comforting, chef-tested meals around what you already have at home.',
      features: [
        _FeatureItem(
          icon: Icons.kitchen_outlined,
          tintColor: Color(0xFF2E6349),
          title: "Cook with what's in your fridge",
        ),
        _FeatureItem(
          icon: Icons.eco_outlined,
          tintColor: Color(0xFF2E6349),
          title: "Zero food waste & grocery savings",
        ),
      ],
    ),
    const _OnboardingSlideData(
      imageAsset: SproutAssets.onboardingIngredients,
      badgeText: 'AI INGREDIENT SCANNER',
      badgeIcon: Icons.camera_alt_rounded,
      headline: 'Snap your ingredients.\nGet instant recipes.',
      bodyText: 'Point your camera at fresh produce, dairy, or spices. Sprout recognizes them in real-time and pairs them instantly.',
      features: [
        _FeatureItem(
          icon: Icons.camera_alt_outlined,
          tintColor: Color(0xFF2E6349),
          title: "Fast photo-based ingredient recognition",
        ),
        _FeatureItem(
          icon: Icons.swap_horiz_rounded,
          tintColor: Color(0xFF2E6349),
          title: "Smart pantry ingredient substitutes",
        ),
      ],
    ),
    const _OnboardingSlideData(
      imageAsset: SproutAssets.onboardingBetterCooking,
      badgeText: 'GUIDED COOKING',
      badgeIcon: Icons.timer_outlined,
      headline: 'Cook with confidence\nat your own pace.',
      bodyText: 'Step-by-step guidance, built-in smart timers, and audio instructions make every dish effortless and foolproof.',
      features: [
        _FeatureItem(
          icon: Icons.timer_outlined,
          tintColor: Color(0xFF2E6349),
          title: "Interactive smart timers for each step",
        ),
        _FeatureItem(
          icon: Icons.volume_up_outlined,
          tintColor: Color(0xFF2E6349),
          title: "Hands-free step audio instructions",
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sprout_has_completed_onboarding', true);
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _selectDiet(String? diet) {
    HapticFeedback.selectionClick();
    final current = ref.read(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    // Remove any currently selected diet
    for (final d in _dietOptions) {
      if (current.contains(d)) {
        notifier.toggle(d);
      }
    }
    // Add the newly selected diet (if not "No preference")
    if (diet != null) {
      notifier.toggle(diet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        SproutColors.isDarkMode;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: SproutScaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Main PageView spanning full screen
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: 4,
              itemBuilder: (context, index) {
                if (index < 3) {
                  return _buildHeroSlide(context, _slides[index]);
                } else {
                  return _buildPersonalizationSlide(context);
                }
              },
            ),

            // Seamless Bottom Navigation Dock integrated directly into canvas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavDock(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSlide(BuildContext context, _OnboardingSlideData data) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        SproutColors.isDarkMode;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Full-bleed responsive hero height occupying ~46% of the screen
    final heroHeight = (screenHeight * 0.46).clamp(340.0, 440.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Full-bleed Hero Artwork starting at top = 0 (behind status bar & header)
          OnboardingHero(
            imageAsset: data.imageAsset,
            backgroundColor: backgroundColor,
            height: heroHeight,
            borderRadius: null,
            imageAlignment: const Alignment(0, -0.20),
            sigma: 4.0,
            blurBottom: 0.18,
            quality: BlurQuality.medium,
          ),

          // 2. Free-standing content directly on page background (no boxes, no cards)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Free-standing Eyebrow Label (NO pill container or border)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      data.badgeIcon,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF4ADE80)
                          : SproutColors.sproutGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.badgeText,
                      style: SproutTypography.caption(
                        color: isDark
                            ? const Color(0xFF4ADE80)
                            : SproutColors.sproutGreen,
                        fontWeight: FontWeight.w700,
                      ).copyWith(letterSpacing: 1.2, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Editorial Headline
                SproutMetallicHeading(
                  data.headline,
                  textAlign: TextAlign.center,
                  style:
                      SproutTypography.h1(
                        color: isDark
                            ? SproutColors.metallicGoldBase
                            : SproutColors.sproutGreen,
                      ).copyWith(
                        height: 1.16,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 10),

                // Legible body text directly on background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    data.bodyText,
                    textAlign: TextAlign.center,
                    style: SproutTypography.body(
                      color: isDark
                          ? SproutColors.nightPrimaryInk.withValues(alpha: 0.88)
                          : const Color(0xFF2E4336),
                    ).copyWith(height: 1.45, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),

                // Feature Highlights: clean icon-and-text rows directly on background with vertical divider
                ...data.features.map((feat) => _buildFeatureRow(feat, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureItem feat, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botanical / kitchen icon
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(
                feat.icon,
                size: 24,
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : SproutColors.sproutGreen,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Delicate vertical divider bar
          Container(
            width: 1.2,
            height: 24,
            color: isDark
                ? SproutColors.sage.withValues(alpha: 0.35)
                : SproutColors.sage.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 14),

          // High-contrast legible feature title
          Expanded(
            child: Text(
              feat.title,
              style: SproutTypography.body(
                color: isDark
                    ? SproutColors.nightPrimaryInk
                    : SproutColors.sproutGreen,
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: 15, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationSlide(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        SproutColors.isDarkMode;
    final topPadding = MediaQuery.of(context).padding.top;
    final selected = ref.watch(preferencesProvider);

    // Active diet (if any)
    final activeDiet = selected.firstWhere(
      (p) => _dietOptions.contains(p),
      orElse: () => '',
    );

    const restrictions = [
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'Low Sodium',
    ];
    const rhythms = ['Quick 20-min meals', 'One-pot meals', 'High protein'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 115),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Compact Chef Sprout Mascot with warm glow
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? const Color(0xFF4ADE80) : SproutColors.sage)
                            .withValues(alpha: isDark ? 0.3 : 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  SproutAssets.onboardingSproutCooking,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 80),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Eyebrow Tag Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2E6349).withValues(alpha: 0.3)
                    : SproutColors.sproutGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                      : SproutColors.sproutGreen.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : SproutColors.sproutGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'TASTE PROFILE SETUP',
                    style: SproutTypography.caption(
                      color: isDark
                          ? const Color(0xFF4ADE80)
                          : SproutColors.sproutGreen,
                      fontWeight: FontWeight.w700,
                    ).copyWith(letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Headline
          Center(
            child: SproutMetallicHeading(
              'Personalize your kitchen',
              style: SproutTypography.h2().copyWith(fontSize: 23),
            ),
          ),
          const SizedBox(height: 4),

          // 4. Subtitle
          Center(
            child: Text(
              'Select any that apply, or continue with no restrictions.',
              textAlign: TextAlign.center,
              style: SproutTypography.body(
                color: isDark
                    ? SproutColors.nightPrimaryInk.withValues(alpha: 0.88)
                    : const Color(0xFF2A3D32),
              ).copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Section 1: Dietary Pattern (Single Choice)
          Text(
            '🥗 Dietary Pattern (Pick one)',
            style: SproutTypography.smallBold(color: SproutColors.primaryInk),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SproutFilterChip(
                label: 'No preference',
                isSelected: activeDiet.isEmpty,
                onSelected: () => _selectDiet(null),
              ),
              ..._dietOptions.map((diet) {
                final isSelected = activeDiet == diet;
                return SproutFilterChip(
                  label: diet,
                  isSelected: isSelected,
                  onSelected: () => _selectDiet(isSelected ? null : diet),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // Section 2: Allergies & Restrictions (Multi-select)
          Text(
            '🛡️ Dietary Restrictions (Select any)',
            style: SproutTypography.smallBold(color: SproutColors.primaryInk),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: restrictions.map((item) {
              final isSelected = selected.contains(item);
              return SproutFilterChip(
                label: item,
                isSelected: isSelected,
                onSelected: () {
                  ref.read(preferencesProvider.notifier).toggle(item);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Section 3: Cooking Rhythm (Multi-select)
          Text(
            '⚡ Cooking Rhythm',
            style: SproutTypography.smallBold(color: SproutColors.primaryInk),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rhythms.map((item) {
              final isSelected = selected.contains(item);
              return SproutFilterChip(
                label: item,
                isSelected: isSelected,
                onSelected: () {
                  ref.read(preferencesProvider.notifier).toggle(item);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavDock(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        SproutColors.isDarkMode;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withValues(alpha: 0.0),
            backgroundColor.withValues(alpha: 0.85),
            backgroundColor,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center: Progress Indicator (Active elongated pill + Inactive dots)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (index) {
                      final isActive = _currentPage == index;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        child: AnimatedContainer(
                          duration: SproutMotion.medium,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                      ? const Color(0xFF4ADE80)
                                      : SproutColors.sproutGreen)
                                : (isDark
                                      ? SproutColors.nightSecondaryInk
                                          .withValues(alpha: 0.35)
                                      : SproutColors.sage
                                          .withValues(alpha: 0.45)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom-left: Skip button on slide 0, Backward button on slide > 0
                Align(
                  alignment: Alignment.centerLeft,
                  child: _currentPage == 0
                      ? SproutBouncyTap(
                          key: const Key('onboarding_skip_button'),
                          onTap: _finishOnboarding,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                            child: Text(
                              'Skip',
                              style: SproutTypography.body(
                                color: isDark
                                    ? SproutColors.nightSecondaryInk
                                    : SproutColors.sproutGreen,
                              ).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : SproutBouncyTap(
                          key: const Key('onboarding_back_button'),
                          onTap: _previousPage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? SproutColors.nightSurface.withValues(
                                      alpha: 0.85,
                                    )
                                  : Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? SproutColors.sage.withValues(alpha: 0.3)
                                    : SproutColors.sage.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.06,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: isDark
                                  ? SproutColors.nightPrimaryInk
                                  : SproutColors.sproutGreen,
                              size: 22,
                            ),
                          ),
                        ),
                ),

                // Bottom-right: Forward button
                Align(
                  alignment: Alignment.centerRight,
                  child: SproutBouncyTap(
                    key: const Key('onboarding_next_button'),
                    onTap: _nextPage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E6349)
                            : SproutColors.sproutGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? const Color(0xFF4ADE80)
                                        : SproutColors.sproutGreen)
                                    .withValues(alpha: isDark ? 0.35 : 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentPage == 3
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
