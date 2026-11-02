import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design/colors.dart';
import '../../../design/glass.dart';
import '../../../design/sprout_haptics.dart';
import '../../../design/typography.dart';
import '../../../models/meal_plan_item.dart';
import '../../../models/recipe.dart';
import '../../../providers/app_providers.dart';
import '../../planner/meal_planner_screen.dart';

/// Frosted Glass "Add to Plan" Modal Bottom Sheet matching the reference UI.
class AddToPlanGlassSheet extends ConsumerStatefulWidget {
  final Recipe recipe;
  final int initialServings;

  const AddToPlanGlassSheet({
    super.key,
    required this.recipe,
    this.initialServings = 4,
  });

  static Future<void> show(
    BuildContext context, {
    required Recipe recipe,
    int initialServings = 4,
  }) {
    return SproutGlassModalSheet.show(
      context: context,
      builder: (_) => AddToPlanGlassSheet(
        recipe: recipe,
        initialServings: initialServings,
      ),
    );
  }

  @override
  ConsumerState<AddToPlanGlassSheet> createState() => _AddToPlanGlassSheetState();
}

class _AddToPlanGlassSheetState extends ConsumerState<AddToPlanGlassSheet> {
  late DateTime _selectedDate;
  late MealType _selectedMeal;
  late int _servings;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedMeal = MealType.dinner;
    _servings = widget.initialServings > 0 ? widget.initialServings : 4;
  }

  Future<void> _pickDate() async {
    SproutHaptics.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SproutColors.glassWarmAmber,
              onPrimary: Colors.black,
              surface: Color(0xFF221E1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePlan() async {
    SproutHaptics.medium();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final dayOfWeek = _selectedDate.weekday; // 1 = Mon, 7 = Sun
    final formattedDate = DateFormat('MMM d').format(_selectedDate);

    Navigator.of(context).pop();

    await ref.read(mealPlanProvider.notifier).addOrUpdateMeal(
          dayOfWeek: dayOfWeek,
          mealType: _selectedMeal,
          recipe: widget.recipe.copyWith(servings: _servings),
        );

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF241F1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Planned "${widget.recipe.title}" for $formattedDate (${_selectedMeal.label})! 🗓️',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'View Plan',
          textColor: SproutColors.glassWarmAmber,
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
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Header: [X] Close  |  "Add to Plan"  |  [📅] Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SproutGlassCircleButton(
                iconData: Icons.close_rounded,
                size: 40,
                iconSize: 18,
                tooltip: 'Close',
                onTap: () => Navigator.of(context).pop(),
              ),
              Text(
                'Add to Plan',
                style: SproutTypography.h3(color: Colors.white),
              ),
              SproutGlassCircleButton(
                iconData: Icons.calendar_today_rounded,
                size: 40,
                iconSize: 18,
                tooltip: 'Confirm Date',
                onTap: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // "When" Section Header
          Text(
            'When',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),

          // Date Row: "Date" on left, frosted date pill on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SproutGlassBadgePill(
                text: formattedDate,
                onTap: _pickDate,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Meal selection segmented track (Breakfast, Lunch, Dinner, Snack)
          SproutGlassSegmentedTrack<MealType>(
            items: MealType.values,
            selectedItem: _selectedMeal,
            onSelected: (meal) => setState(() => _selectedMeal = meal),
            labelBuilder: (m) => m.label,
          ),
          const SizedBox(height: 24),

          // Servings row: "4 servings" on left, glass stepper capsule on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_servings ${_servings == 1 ? 'serving' : 'servings'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SproutGlassStepper(
                value: _servings,
                min: 1,
                max: 24,
                onChanged: (v) => setState(() => _servings = v),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Primary Save Action Button (Solid warm cream pill button)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SproutColors.glassCreamPill,
                foregroundColor: SproutColors.glassCreamPillText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: _savePlan,
              child: const Text(
                'Save to Meal Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
