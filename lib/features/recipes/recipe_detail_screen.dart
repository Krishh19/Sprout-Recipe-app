import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ingredient_matcher.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_button.dart';
import '../../design/components/sprout_diet_badge.dart';
import '../../design/components/sprout_metallic_text.dart';
import '../../design/components/sprout_recipe_image.dart';
import '../../design/components/sprout_substitution_card.dart';
import '../../design/radii.dart';
import '../../design/sprout_ingredient_scaler.dart';
import '../../design/typography.dart';
import '../../models/meal_plan_item.dart';
import '../../models/nutrition_info.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../../repositories/nutrition_service.dart';
import '../cooking/cooking_screen.dart';
import '../planner/meal_planner_screen.dart';
import '../shopping/shopping_list_screen.dart';
import 'widgets/recipe_share_card_sheet.dart';
import '../../services/groq_service.dart';
import '../../services/recipe_translation_service.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Recipe _recipe;
  late int _servings;
  late bool _isSaved;
  bool _isLoadingDetails = false;
  bool _hasAddedToShoppingList = false;

  // Bilingual Translation State
  String _currentLanguage = 'en'; // 'en' or 'hi'
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _recipe = widget.recipe;
    _servings = 1;
    _isSaved = widget.recipe.isSaved;

    final isSourceHindi = RecipeTranslationService.isRecipeHindi(widget.recipe);
    _currentLanguage = isSourceHindi ? 'hi' : 'en';

    if (_recipe.ingredients.isEmpty || _recipe.instructions.isEmpty) {
      _loadFullRecipe();
    }
  }

  Future<void> _toggleLanguage() async {
    final targetLang = _currentLanguage == 'hi' ? 'en' : 'hi';
    setState(() => _isTranslating = true);
    HapticFeedback.lightImpact();
    try {
      final translated = await RecipeTranslationService().translateRecipe(
        widget.recipe,
        targetLanguage: targetLang,
      );
      if (mounted) {
        setState(() {
          _currentLanguage = targetLang;
          _recipe = translated.copyWith(
            isSaved: _isSaved,
            servings: _servings > 0 ? _servings : 1,
          );
          _isTranslating = false;
        });
      }
    } catch (e) {
      debugPrint('Error translating recipe in detail screen: $e');
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _loadFullRecipe() async {
    setState(() => _isLoadingDetails = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final full = await repo.fetchRecipeById(_recipe.id);
      if (full != null && mounted) {
        setState(() {
          _recipe = full.copyWith(
            isSaved: _isSaved,
            servings: _servings > 0 ? _servings : 1,
          );
          _isLoadingDetails = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });
    ref.read(savedRecipesProvider.notifier).toggleFavorite(_recipe);
  }

  void _showShareCardSheet() {
    HapticFeedback.lightImpact();
    RecipeShareCardSheet.show(context, recipe: _recipe);
  }

  void _showAddToPlanSheet() {
    int selectedDay = DateTime.now().weekday; // 1-7
    final hour = DateTime.now().hour;
    MealType selectedMeal = hour < 11
        ? MealType.breakfast
        : hour < 15
            ? MealType.lunch
            : hour < 18
                ? MealType.snack
                : MealType.dinner;

    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: SproutColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: SproutColors.sage.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add to Meal Plan 🗓️', style: SproutTypography.h3()),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Schedule "${_recipe.title}" into your weekly routine',
                      style: SproutTypography.caption(
                        color: SproutColors.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select Day:',
                      style: SproutTypography.smallBold(
                        color: SproutColors.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (idx) {
                          final dayIdx = idx + 1;
                          final isSel = selectedDay == dayIdx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(shortDays[idx]),
                              selected: isSel,
                              selectedColor: SproutColors.sproutGreen,
                              labelStyle: TextStyle(
                                color:
                                    isSel ? Colors.white : SproutColors.primaryInk,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedDay = dayIdx);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select Meal Time:',
                      style: SproutTypography.smallBold(
                        color: SproutColors.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MealType.values.map((m) {
                        final isSel = selectedMeal == m;
                        return ChoiceChip(
                          avatar: Text(m.emoji),
                          label: Text(m.label),
                          selected: isSel,
                          selectedColor: SproutColors.sproutGreen,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : SproutColors.primaryInk,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedMeal = m);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SproutButton(
                      label: 'Save to Plan',
                      width: double.infinity,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        HapticFeedback.mediumImpact();
                        Navigator.of(ctx).pop();
                        await ref.read(mealPlanProvider.notifier).addOrUpdateMeal(
                              dayOfWeek: selectedDay,
                              mealType: selectedMeal,
                              recipe: _recipe,
                            );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: SproutColors.primaryInk,
                            content: Text(
                              'Planned for ${shortDays[selectedDay - 1]} ${selectedMeal.label}! 🗓️',
                            ),
                            action: SnackBarAction(
                              label: 'View Plan',
                              textColor: SproutColors.sproutGreen,
                              onPressed: () {
                                nav.push(
                                  MaterialPageRoute(
                                    builder: (_) => const MealPlannerScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.38;
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    // Theme-adaptive top navigation button tokens for optimal readability over food photos
    final navBtnBg = isDark
        ? const Color(0xCC1A241F)
        : Colors.white.withValues(alpha: 0.88);
    final navBtnBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.6);
    final navBtnShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.08);
    final navBtnIconColor = isDark
        ? Colors.white
        : SproutColors.lightPrimaryInk;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? SproutColors.nightSkyBackgroundGradient
                    : SproutColors.lightSkyBackgroundGradient,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Hero Image & Overlay AppBar
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Hero Food Image with Shared Element Transition & Subtle Rounded Lower Corners (Section 2.2)
                    Hero(
                      tag: 'recipe_image_${_recipe.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                        child: SizedBox(
                          height: heroHeight,
                          width: double.infinity,
                          child: SproutRecipeImage(
                            imageUrl: _recipe.imageUrl,
                            cuisine: _recipe.cuisine,
                            title: _recipe.title,
                            height: heroHeight,
                            width: double.infinity,
                            isDetail: true,
                          ),
                        ),
                      ),
                    ),

                    // Top Navigation Action Icons: Back on left, Share & Favorite on right (Section 2.3)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            SproutBouncyTap(
                              onTap: () => Navigator.of(context).pop(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: navBtnBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: navBtnBorder,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: navBtnShadow,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: navBtnIconColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Action Buttons: Language Switcher, Share, Favorite
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Language Switcher Button [ 🌐 EN | HI ]
                                SproutBouncyTap(
                                  onTap: _isTranslating ? null : _toggleLanguage,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: navBtnBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: navBtnBorder,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: navBtnShadow,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isTranslating)
                                              SizedBox(
                                                width: 13,
                                                height: 13,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: navBtnIconColor,
                                                ),
                                              )
                                            else
                                              const Text('🌐', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _currentLanguage == 'hi' ? 'HI' : 'EN',
                                              style: TextStyle(
                                                color: navBtnIconColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Share Button
                                SproutBouncyTap(
                                  onTap: _showShareCardSheet,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: navBtnBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: navBtnBorder,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: navBtnShadow,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.share_outlined,
                                          color: navBtnIconColor,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Heart Save Button
                                SproutBouncyTap(
                                  onTap: _toggleSave,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: navBtnBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: navBtnBorder,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: navBtnShadow,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isSaved
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: _isSaved
                                              ? SproutColors.tomato
                                              : navBtnIconColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recipe Body Details
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: SproutColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  transform: Matrix4.translationValues(0.0, -24.0, 0.0),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Banner if navigated from Scanner
                      if (_recipe.matchPercentage > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: SproutColors.sproutGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_recipe.matchPercentage.toInt()}% Pantry Match',
                                style: SproutTypography.smallBold(
                                  color: SproutColors.sproutGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Title (Section 2.1 & 20: Clean 2-7 word display title with golden metallic finish in dark mode)
                      SproutMetallicHeading(
                        _recipe.displayTitle,
                        style: SproutTypography.h2().copyWith(fontSize: 26),
                      ),
                      if (_recipe.subtitle != null && _recipe.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _recipe.subtitle!,
                          style: SproutTypography.body(
                            color: SproutColors.leaf,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Meta Row: Diet, Rating, Time, Servings, Cuisine + secondary Plan button (Sections 19 & 2.3)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                SproutDietBadge(diet: _recipe.diet, size: 16),
                                if (_recipe.rating != null) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: SproutColors.butter,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _recipe.rating!.toStringAsFixed(1),
                                        style: SproutTypography.bodyBold(),
                                      ),
                                    ],
                                  ),
                                  Text('·', style: SproutTypography.smallBold(color: SproutColors.sage)),
                                ],
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: SproutColors.secondaryInk,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_recipe.totalTimeMins} min',
                                      style: SproutTypography.body(
                                        color: SproutColors.secondaryInk,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('·', style: SproutTypography.smallBold(color: SproutColors.sage)),
                                Text(
                                  '$_servings ${_servings == 1 ? 'serving' : 'servings'}',
                                  style: SproutTypography.body(
                                    color: SproutColors.secondaryInk,
                                  ),
                                ),
                                if (_recipe.cuisine.trim().isNotEmpty) ...[
                                  Text('·', style: SproutTypography.smallBold(color: SproutColors.sage)),
                                  Text(
                                    _recipe.cuisine,
                                    style: SproutTypography.body(
                                      color: SproutColors.secondaryInk,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Secondary Plan button (Section 2.3)
                          SproutBouncyTap(
                            onTap: _showAddToPlanSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : SproutColors.sproutGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.30)
                                      : SproutColors.sproutGreen.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 14,
                                    color: isDark ? const Color(0xFF68D391) : SproutColors.sproutGreen,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Plan',
                                    style: SproutTypography.caption(
                                      color: isDark ? const Color(0xFF68D391) : SproutColors.sproutGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        _recipe.description,
                        style: SproutTypography.body(
                          color: SproutColors.secondaryInk,
                        ).copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Serving Size Adjuster
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.canvas,
                          borderRadius: SproutRadii.borderMd,
                          border: Border.all(
                            color: SproutColors.sage.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Servings',
                              style: SproutTypography.bodyBold(),
                            ),
                            Row(
                              children: [
                                _buildAdjustButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_servings > 1) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _servings--);
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    '$_servings',
                                    style: SproutTypography.bodyBold(
                                      color: SproutColors.sproutGreen,
                                    ),
                                  ),
                                ),
                                _buildAdjustButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    if (_servings < 24) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _servings++);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Bar (Section 11: Lighter editorial treatment with underline)
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0x1F8DA399),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: const UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 2.5,
                              color: SproutColors.sproutGreen,
                            ),
                            insets: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          labelColor: SproutColors.primaryInk,
                          unselectedLabelColor: SproutColors.muted,
                          labelStyle: SproutTypography.bodyBold().copyWith(fontSize: 14),
                          unselectedLabelStyle: SproutTypography.body().copyWith(fontSize: 14),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Ingredients'),
                            Tab(text: 'Steps'),
                            Tab(text: 'Nutrition'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab View Content
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          switch (_tabController.index) {
                            case 0:
                              return _buildIngredientsList();
                            case 1:
                              return _buildStepsList();
                            case 2:
                            default:
                              return _buildNutritionInfo();
                          }
                        },
                      ),
                      // Generous bottom clearance to ensure content scrolls completely clear of floating cooking bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Fixed "Start Cooking" Button (Theme-adaptive glass container)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? SproutColors.nightSurface.withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : SproutColors.sage.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
              child: SproutButton(
                label: _currentLanguage == 'hi' ? 'पकाना शुरू करें →' : 'Start Cooking →',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CookingScreen(recipe: _recipe),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SproutColors.sage.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: SproutColors.primaryInk),
      ),
    );
  }

  Widget _buildIngredientsList() {
    final scale = _servings / (_recipe.servings > 0 ? _recipe.servings : 1);
    final missing = _recipe.missingIngredients;
    final hasMissing = missing.isNotEmpty;

    if (_isLoadingDetails) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36.0),
          child: CircularProgressIndicator(color: SproutColors.sproutGreen),
        ),
      );
    }

    if (_recipe.ingredients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              const Icon(Icons.menu_book_rounded, size: 36, color: SproutColors.sage),
              const SizedBox(height: 8),
              Text(
                'Ingredients are being prepared for this recipe.',
                style: SproutTypography.body(color: SproutColors.secondaryInk),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Actionable Shopping List Utility Card (Section 4)
        Builder(
          builder: (context) {
            final pantry = ref.watch(pantryProvider).value ?? [];
            final normPantry = pantry.map((e) => e.toLowerCase()).toList();
            final inPantryCount = _recipe.ingredients.where((i) {
              final l = i.toLowerCase();
              return normPantry.any((p) => l.contains(p) || p.contains(l));
            }).length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _hasAddedToShoppingList
                    ? SproutColors.sproutGreen.withValues(alpha: 0.08)
                    : SproutColors.canvas,
                borderRadius: SproutRadii.borderMd,
                border: Border.all(
                  color: _hasAddedToShoppingList
                      ? SproutColors.sproutGreen.withValues(alpha: 0.25)
                      : SproutColors.sage.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasAddedToShoppingList
                        ? Icons.check_circle_rounded
                        : Icons.shopping_basket_outlined,
                    color: SproutColors.sproutGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _hasAddedToShoppingList
                              ? 'Added to shopping list ✓'
                              : 'Shopping list',
                          style: SproutTypography.smallBold(
                            color: SproutColors.primaryInk,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _hasAddedToShoppingList
                              ? '${_recipe.ingredients.length} ingredients'
                              : '${_recipe.ingredients.length} ingredients needed'
                                  '${inPantryCount > 0 ? ' · $inPantryCount already in pantry' : ''}',
                          style: SproutTypography.caption(
                            color: SproutColors.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_hasAddedToShoppingList)
                    SproutBouncyTap(
                      onTap: () {
                        final rawItems = hasMissing ? missing : _recipe.ingredients;
                        final itemsToAdd = rawItems
                            .map((i) => SproutIngredientScaler.scale(i, scale))
                            .toList();
                        ref.read(shoppingListProvider.notifier).addItems(
                          itemsToAdd,
                          recipeTitle: _recipe.displayTitle,
                        );
                        HapticFeedback.lightImpact();
                        setState(() => _hasAddedToShoppingList = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.sproutGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+ Add all',
                          style: SproutTypography.caption(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    SproutBouncyTap(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShoppingListScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'View list →',
                          style: SproutTypography.caption(
                            color: SproutColors.sproutGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Ingredients split by pantry availability: You have / You're missing
        ..._buildSplitIngredients(missing, scale),

        const SizedBox(height: 16),

        // AI-Powered Pantry Substitution Assistant Card (Gemini 3.6 Flash)
        SproutSubstitutionCard(
          missingIngredients: hasMissing
              ? missing
              : (_recipe.cleanedIngredients.isNotEmpty
                  ? _recipe.cleanedIngredients.take(2).toList()
                  : _recipe.ingredients.take(2).toList()),
          recipeTitle: _recipe.title,
        ),
      ],
    );
  }

  List<Widget> _buildSplitIngredients(List<String> missing, double scale) {
    final pantry = ref.watch(pantryProvider).value ?? [];
    final normPantry = pantry.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    bool isHave(String ing) {
      return normPantry.any((p) => IngredientMatcher.isMatch(userItem: p, recipeIngredient: ing));
    }

    bool isMissing(String ing) => missing.any(
          (m) =>
              IngredientMatcher.isMatch(userItem: m, recipeIngredient: ing) ||
              IngredientMatcher.isMatch(userItem: ing, recipeIngredient: m),
        );

    // Only split when we actually have pantry data; otherwise single flat list
    if (pantry.isEmpty) {
      return _recipe.ingredients
          .map((ing) => _buildIngredientRow(ing, isMissing(ing), scale))
          .toList();
    }

    final have = _recipe.ingredients
        .where((i) => isHave(i) && !isMissing(i))
        .toList();
    final need = _recipe.ingredients
        .where((i) => isMissing(i) || !isHave(i))
        .toList();

    final widgets = <Widget>[];
    if (have.isNotEmpty) {
      widgets.add(_buildIngredientGroupHeader(
        icon: Icons.check_circle_rounded,
        color: SproutColors.sproutGreen,
        title: 'You have (${have.length})',
      ));
      widgets.addAll(have.map((ing) => _buildIngredientRow(ing, false, scale)));
    }
    if (need.isNotEmpty) {
      widgets.add(_buildIngredientGroupHeader(
        icon: Icons.shopping_basket_outlined,
        color: SproutColors.tomato,
        title: 'You need (${need.length})',
      ));
      widgets.addAll(need.map((ing) => _buildIngredientRow(ing, true, scale)));
    }
    return widgets;
  }

  Widget _buildIngredientGroupHeader({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: SproutTypography.smallBold(color: color)),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(String ing, bool isMissing, double scale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMissing
            ? SproutColors.tomato.withValues(alpha: 0.05)
            : SproutColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: isMissing
            ? Border.all(color: SproutColors.tomato.withValues(alpha: 0.25))
            : Border.all(color: SproutColors.sage.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isMissing ? SproutColors.tomato : SproutColors.sproutGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SproutIngredientScaler.scale(ing, scale),
              style: SproutTypography.body(fontWeight: FontWeight.w500).copyWith(fontSize: 14.5),
            ),
          ),
          if (isMissing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: SproutColors.tomato.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Missing',
                style: SproutTypography.caption(
                  color: SproutColors.tomato,
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 11),
              ),
            ),
          if (scale != 1.0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '(${scale.toStringAsFixed(1)}x)',
                style: SproutTypography.caption(color: SproutColors.sage),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    if (_isLoadingDetails) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36.0),
          child: CircularProgressIndicator(color: SproutColors.sproutGreen),
        ),
      );
    }

    if (_recipe.instructions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              const Icon(Icons.timer_outlined, size: 36, color: SproutColors.sage),
              const SizedBox(height: 8),
              Text(
                'Step-by-step instructions are being prepared.',
                style: SproutTypography.body(color: SproutColors.secondaryInk),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_recipe.instructions.length, (index) {
        final step = _recipe.instructions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: SproutColors.sproutGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: SproutTypography.caption(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  step,
                  style: SproutTypography.body().copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNutritionInfo() {
    final nutritionAsync = ref.watch(recipeNutritionProvider(_recipe));
    final scale = _servings / (_recipe.servings > 0 ? _recipe.servings : 1);

    return nutritionAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SproutColors.canvas,
          borderRadius: SproutRadii.borderMd,
          border: Border.all(color: SproutColors.sage.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SproutColors.sproutGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GroqService().isAvailable
                        ? 'Calculating nutrition with Qwen 3.8...'
                        : 'Calculating nutrition with Gemini...',
                    style: SproutTypography.caption(color: SproutColors.secondaryInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: SproutColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ],
        ),
      ),
      error: (_, _) {
        final fallback = NutritionService.calculateHeuristicNutrition(_recipe);
        return _buildNutritionContent(fallback, scale);
      },
      data: (info) => _buildNutritionContent(info, scale),
    );
  }

  Widget _buildNutritionContent(NutritionInfo info, double scale) {
    final cal = (info.calories * scale).round();
    final protein = (info.proteinG * scale).round();
    final carbs = (info.carbsG * scale).round();
    final fat = (info.fatG * scale).round();
    final fiber = (info.fiberG * scale).round();

    final totalMacros = (protein + carbs + fat).clamp(1, 9999);
    final pPct = (protein / totalMacros * 100).round();
    final cPct = (carbs / totalMacros * 100).round();
    final fPct = (100 - pPct - cPct).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SproutColors.canvas,
        borderRadius: SproutRadii.borderMd,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$cal',
                    style: SproutTypography.h2(
                      color: SproutColors.primaryInk,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'kcal',
                    style: SproutTypography.body(
                      color: SproutColors.secondaryInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: SproutColors.sproutGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SproutColors.sproutGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: SproutColors.sproutGreen,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          info.isAiEstimated
                              ? (GroqService().isAvailable ? 'Qwen 3.8' : 'AI Estimate')
                              : 'Macro Est.',
                          style: SproutTypography.caption(
                            color: SproutColors.sproutGreen,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            scale == 1.0
                ? 'Per serving (${_recipe.servings} ${_recipe.servings == 1 ? 'serving' : 'servings'})'
                : 'Total for $_servings (${info.calories} kcal/serving)',
            style: SproutTypography.caption(
              color: SproutColors.secondaryInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Visual Macro Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(flex: pPct.clamp(1, 100), child: Container(color: SproutColors.sproutGreen)),
                  const SizedBox(width: 2),
                  Expanded(flex: cPct.clamp(1, 100), child: Container(color: SproutColors.butter)),
                  const SizedBox(width: 2),
                  Expanded(flex: fPct.clamp(1, 100), child: Container(color: SproutColors.carrot)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildMacroRow('Protein', '${protein}g', '$pPct%', SproutColors.sproutGreen),
          const Divider(height: 16, thickness: 0.5, color: Color(0x1F8DA399)),
          _buildMacroRow('Carbohydrates', '${carbs}g', '$cPct%', SproutColors.butter),
          const Divider(height: 16, thickness: 0.5, color: Color(0x1F8DA399)),
          _buildMacroRow('Fat', '${fat}g', '$fPct%', SproutColors.carrot),
          const Divider(height: 16, thickness: 0.5, color: Color(0x1F8DA399)),
          _buildMacroRow('Dietary Fiber', '${fiber}g', null, SproutColors.sage),

          if (info.healthNote != null && info.healthNote!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: SproutColors.sage.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.healthNote!,
                      style: SproutTypography.caption(
                        color: SproutColors.primaryInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, String? percentage, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: SproutTypography.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(width: 6),
                Text(
                  '($percentage)',
                  style: SproutTypography.caption(color: SproutColors.secondaryInk),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: SproutTypography.bodyBold()),
      ],
    );
  }
}
