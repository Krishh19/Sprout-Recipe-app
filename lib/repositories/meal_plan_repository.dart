import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan_item.dart';

class MealPlanRepository {
  static const String _key = 'sprout_meal_plan_items';

  Future<List<MealPlanItem>> fetchMealPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return MealPlanItem.fromJson(decoded);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MealPlanItem>> saveMealPlan(List<MealPlanItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = items.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_key, encoded);
    } catch (_) {}
    return items;
  }

  Future<List<MealPlanItem>> addOrUpdateItem(MealPlanItem item) async {
    final current = await fetchMealPlan();
    current.removeWhere((i) =>
        i.id == item.id ||
        (i.dayOfWeek == item.dayOfWeek && i.mealType == item.mealType));
    current.add(item);
    return saveMealPlan(current);
  }

  Future<List<MealPlanItem>> removeItem(String id) async {
    final current = await fetchMealPlan();
    current.removeWhere((i) => i.id == id);
    return saveMealPlan(current);
  }

  Future<List<MealPlanItem>> clearWeek() async {
    return saveMealPlan([]);
  }
}
