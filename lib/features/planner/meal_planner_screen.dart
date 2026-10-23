import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_diet_badge.dart';

import '../../design/components/sprout_recipe_image.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/radii.dart';
import '../../design/typography.dart';
import '../../models/meal_plan_item.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../cooking/cooking_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import '../shopping/shopping_list_screen.dart';
import 'widgets/recipe_picker_sheet.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  late int _selectedDay; // 1 = Monday, 7 = Sunday

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _shortDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday; // 1-7
  }

  DateTime _getDateForDay(int dayOfWeek) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = today.weekday; // 1-7
    final diff = dayOfWeek - currentWeekday;
    return today.add(Duration(days: diff));
  }

  String _getMonthRangeLabel() {
    final monday = _getDateForDay(1);
    final sunday = _getDateForDay(7);
    if (monday.month == sunday.month) {
      return '${_monthNames[monday.month - 1].toUpperCase()} ${monday.year}';
    } else {
      return '${_shortMonthNames[monday.month - 1].toUpperCase()} – ${_shortMonthNames[sunday.month - 1].toUpperCase()} ${sunday.year}';
    }
  }

  Future<void> _exportToGrocery({bool wholeWeek = false}) async {
    HapticFeedback.mediumImpact();
    final count = await ref
        .read(mealPlanProvider.notifier)
        .exportToShoppingList(forDay: wholeWeek ? null : _selectedDay);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SproutColors.primaryInk,
        content: Text(
          count > 0
              ? 'Added $count missing ingredients to your Grocery List! 🛒'
              : 'All ingredients are already in your pantry or grocery list! ✨',
        ),
        action: SnackBarAction(
          label: 'View List',
          textColor: SproutColors.sproutGreen,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickAndAssignMeal(MealType type) async {
    HapticFeedback.lightImpact();
    final picked = await RecipePickerSheet.show(
      context,
      title: 'Choose ${type.label}',
    );

    if (picked != null && mounted) {
      HapticFeedback.selectionClick();
      await ref
          .read(mealPlanProvider.notifier)
          .addOrUpdateMeal(
            dayOfWeek: _selectedDay,
            mealType: type,
            recipe: picked,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealPlan = ref.watch(mealPlanProvider).value ?? [];
    final dayMeals = mealPlan
        .where((m) => m.dayOfWeek == _selectedDay)
        .toList();

    return SproutScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  SproutBouncyTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meal Planner', style: SproutTypography.h3()),
                        Text(
                          'Plan your week & auto-generate groceries',
                          style: SproutTypography.caption(
                            color: SproutColors.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.more_vert_rounded, size: 20),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: SproutRadii.card,
                    ),
                    onSelected: (val) {
                      if (val == 'export_week') {
                        _exportToGrocery(wholeWeek: true);
                      } else if (val == 'clear_day') {
                        for (final m in dayMeals) {
                          ref.read(mealPlanProvider.notifier).removeMeal(m.id);
                        }
                      } else if (val == 'clear_week') {
                        ref.read(mealPlanProvider.notifier).clearWeek();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'export_week',
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_checkout_rounded,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text('Export Week to Grocery List'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_day',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Clear This Day'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_week',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep_rounded,
                              size: 18,
                              color: SproutColors.tomato,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Clear Whole Week',
                              style: TextStyle(color: SproutColors.tomato),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Month Range Header & Jump to Today
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getMonthRangeLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: SproutColors.secondaryInk,
                    ),
                  ),
                  SproutBouncyTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDay = DateTime.now().weekday);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDay == DateTime.now().weekday
                            ? SproutColors.forestGreen.withValues(alpha: 0.12)
                            : SproutColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDay == DateTime.now().weekday
                              ? SproutColors.forestGreen
                              : SproutColors.sage.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: SproutColors.forestGreen,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Today',
                            style: GoogleFonts.inter(
                              color: SproutColors.forestGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Compact Week Day Selector Strip
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final dayIndex = index + 1; // 1-7
                  final isSelected = dayIndex == _selectedDay;
                  final isToday = dayIndex == DateTime.now().weekday;
                  final date = _getDateForDay(dayIndex);
                  final hasMeals = mealPlan.any((m) => m.dayOfWeek == dayIndex);

                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label:
                        '${_dayNames[dayIndex - 1]}, ${date.day} ${_monthNames[date.month - 1]}'
                        '${isToday ? ", Today" : ""}'
                        '${hasMeals ? ", Has planned meals" : ""}',
                    child: SproutBouncyTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDay = dayIndex);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SproutColors.forestGreen
                              : (isToday
                                    ? SproutColors.forestGreen.withValues(
                                        alpha: 0.08,
                                      )
                                    : SproutColors.surface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? SproutColors.forestGreen
                                : (isToday
                                      ? SproutColors.forestGreen.withValues(
                                          alpha: 0.5,
                                        )
                                      : SproutColors.sage.withValues(
                                          alpha: 0.28,
                                        )),
                            width: isSelected ? 1.6 : (isToday ? 1.4 : 1.0),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: SproutColors.forestGreen.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Weekday label ABOVE date (e.g. MON, TUE)
                            Text(
                              _shortDays[index].toUpperCase(),
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : (isToday
                                          ? SproutColors.forestGreen
                                          : SproutColors.secondaryInk),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Date number
                            Text(
                              '${date.day}',
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white
                                    : (isToday
                                          ? SproutColors.forestGreen
                                          : SproutColors.primaryInk),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Dot indicators for Today & Planned Meals
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isToday)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : SproutColors.forestGreen,
                                    ),
                                  ),
                                if (hasMeals)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : (isToday
                                                ? SproutColors.forestGreen
                                                : SproutColors.sproutGreen),
                                    ),
                                  ),
                                if (!isToday && !hasMeals)
                                  const SizedBox(height: 4),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Day Title & Quick Export Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_dayNames[_selectedDay - 1]} Menu 🗓️',
                    style: SproutTypography.h3(),
                  ),
                  if (dayMeals.isNotEmpty)
                    SproutBouncyTap(
                      onTap: () => _exportToGrocery(wholeWeek: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.sproutGreen.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: SproutRadii.borderPill,
                          border: Border.all(
                            color: SproutColors.sproutGreen.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: SproutColors.sproutGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add to Groceries',
                              style: SproutTypography.caption(
                                color: SproutColors.sproutGreen,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Meal Slots List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildMealSlot(MealType.breakfast, dayMeals),
                  const SizedBox(height: 14),
                  _buildMealSlot(MealType.lunch, dayMeals),
                  const SizedBox(height: 14),
                  _buildMealSlot(MealType.snack, dayMeals),
                  const SizedBox(height: 14),
                  _buildMealSlot(MealType.dinner, dayMeals),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(MealType type, List<MealPlanItem> dayMeals) {
    final match = dayMeals.cast<MealPlanItem?>().firstWhere(
      (m) => m?.mealType == type,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(color: SproutColors.sage.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Header
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: SproutTypography.bodyBold().copyWith(fontSize: 15),
              ),
              const Spacer(),
              if (match != null)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: SproutColors.secondaryInk,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(mealPlanProvider.notifier).removeMeal(match.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Meal Content
          if (match != null)
            _buildPlannedRecipeCard(match.recipe)
          else
            _buildEmptySlotCard(type),
        ],
      ),
    );
  }

  Widget _buildPlannedRecipeCard(Recipe recipe) {
    return SproutBouncyTap(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SproutColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SproutColors.sage.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: SproutRecipeImage(
                  imageUrl: recipe.imageUrl,
                  cuisine: recipe.cuisine,
                  height: 68,
                  width: 68,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SproutTypography.bodyBold().copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SproutDietBadge(diet: recipe.diet),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: SproutColors.secondaryInk,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.totalTimeMins}m',
                        style: SproutTypography.caption(
                          color: SproutColors.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cook Button
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SproutColors.sproutGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CookingScreen(recipe: recipe),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlotCard(MealType type) {
    return SproutBouncyTap(
      onTap: () => _pickAndAssignMeal(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: SproutColors.canvas.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SproutColors.sage.withValues(alpha: 0.35),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: SproutColors.sproutGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Add ${type.label}',
              style: SproutTypography.body(color: SproutColors.sproutGreen)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
