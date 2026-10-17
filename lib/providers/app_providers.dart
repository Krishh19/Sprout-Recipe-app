import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';
import '../models/cook_history_item.dart';
import '../models/cook_session.dart';
import '../models/meal_plan_item.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';
import '../repositories/cook_session_repository.dart';
import '../repositories/meal_plan_repository.dart';
import '../repositories/pantry_repository.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/saved_repository.dart';
import '../repositories/scanner_repository.dart';
import '../repositories/shopping_repository.dart';
import '../core/config.dart';
import '../models/nutrition_info.dart';
import '../repositories/nutrition_service.dart';
import '../repositories/substitution_service.dart';
export 'theme_provider.dart';

// Repositories
final recipeRepositoryProvider = Provider((ref) => RecipeRepository());
final savedRepositoryProvider = Provider((ref) => SavedRepository());
final scannerRepositoryProvider = Provider((ref) => ScannerRepository());
final shoppingRepositoryProvider = Provider((ref) => ShoppingRepository());
final substitutionServiceProvider = Provider<SubstitutionService>((ref) {
  if (AppConfig.useGenkitSubstitutions) {
    return GenkitSubstitutionService();
  }
  return GeminiSubstitutionService();
});
final pantryRepositoryProvider = Provider((ref) => PantryRepository());
final cookSessionRepositoryProvider = Provider(
  (ref) => CookSessionRepository(),
);
final mealPlanRepositoryProvider = Provider((ref) => MealPlanRepository());
final nutritionServiceProvider = Provider((ref) => NutritionService());

final recipeNutritionProvider = FutureProvider.family<NutritionInfo, Recipe>((ref, recipe) async {
  final service = ref.watch(nutritionServiceProvider);
  return service.getNutrition(recipe);
});

// Home Carousels
final trendingRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);
  final isVeg = prefs.contains('Vegetarian');
  return repo.fetchTrendingRecipes(limit: 12, diet: isVeg ? 'veg' : null);
});

final quickRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);
  final isVeg = prefs.contains('Vegetarian');
  return repo.fetchQuickRecipes(
    maxMinutes: 30,
    limit: 12,
    diet: isVeg ? 'veg' : null,
  );
});

// Saved Recipes State
class SavedRecipesNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final repo = ref.watch(savedRepositoryProvider);
    return repo.fetchSavedRecipes();
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final repo = ref.read(savedRepositoryProvider);
    final isSaved = await repo.toggleFavorite(recipe);

    state = AsyncData(
      state.value?.map((r) {
            if (r.id == recipe.id) {
              return r.copyWith(isSaved: isSaved);
            }
            return r;
          }).toList() ??
          [],
    );

    // Refresh full list
    final updated = await repo.fetchSavedRecipes();
    state = AsyncData(updated);
  }
}

final savedRecipesProvider =
    AsyncNotifierProvider<SavedRecipesNotifier, List<Recipe>>(
      SavedRecipesNotifier.new,
    );

// Collections State
class CollectionsNotifier extends AsyncNotifier<List<RecipeCollection>> {
  @override
  Future<List<RecipeCollection>> build() async {
    final repo = ref.watch(savedRepositoryProvider);
    return repo.fetchCollections();
  }

  Future<void> addCollection(String name, String description) async {
    final repo = ref.read(savedRepositoryProvider);
    final created = await repo.createCollection(name, description);
    final current = state.value ?? [];
    state = AsyncData([...current, created]);
  }
}

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<RecipeCollection>>(
      CollectionsNotifier.new,
    );

// Dietary Preferences
class PreferencesNotifier extends Notifier<List<String>> {
  static const String _key = 'sprout_user_preferences';

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? const [];
  }

  Future<void> toggle(String pref) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(state);
    if (updated.contains(pref)) {
      updated.remove(pref);
    } else {
      updated.add(pref);
    }
    state = updated;
    await prefs.setStringList(_key, updated);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, List<String>>(
  PreferencesNotifier.new,
);

// Pantry Staples State (Kitchen Essentials)
class PantryStaplesState {
  final List<String> staples;
  final bool isEnabled;

  const PantryStaplesState({this.staples = const [], this.isEnabled = true});

  PantryStaplesState copyWith({List<String>? staples, bool? isEnabled}) {
    return PantryStaplesState(
      staples: staples ?? this.staples,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class PantryStaplesNotifier extends AsyncNotifier<PantryStaplesState> {
  @override
  Future<PantryStaplesState> build() async {
    final repo = ref.watch(pantryRepositoryProvider);
    final staples = await repo.fetchStaples();
    final enabled = await repo.fetchStaplesEnabled();
    return PantryStaplesState(staples: staples, isEnabled: enabled);
  }

  Future<void> toggleEnabled() async {
    final repo = ref.read(pantryRepositoryProvider);
    final current = state.value ?? const PantryStaplesState();
    final next = !current.isEnabled;
    await repo.setStaplesEnabled(next);
    state = AsyncData(current.copyWith(isEnabled: next));
    ref.read(scannerProvider.notifier).findMatches();
  }

  Future<void> toggleStaple(String staple) async {
    final repo = ref.read(pantryRepositoryProvider);
    final updated = await repo.toggleStaple(staple);
    final current = state.value ?? const PantryStaplesState();
    state = AsyncData(current.copyWith(staples: updated));
    ref.read(scannerProvider.notifier).findMatches();
  }

  Future<void> addStaple(String staple) async {
    final repo = ref.read(pantryRepositoryProvider);
    final updated = await repo.addStaple(staple);
    final current = state.value ?? const PantryStaplesState();
    state = AsyncData(current.copyWith(staples: updated));
    ref.read(scannerProvider.notifier).findMatches();
  }

  Future<void> resetToDefaults() async {
    final repo = ref.read(pantryRepositoryProvider);
    final updated = await repo.resetStaples();
    final current = state.value ?? const PantryStaplesState();
    state = AsyncData(current.copyWith(staples: updated));
    ref.read(scannerProvider.notifier).findMatches();
  }
}

final pantryStaplesProvider =
    AsyncNotifierProvider<PantryStaplesNotifier, PantryStaplesState>(
      PantryStaplesNotifier.new,
    );

// Ingredient Scanner & Match state
class ScannerState {
  final List<String> detectedIngredients;
  final bool isScanning;
  final List<Recipe> matchedRecipes;
  final bool isMatching;
  final bool only100PercentMatch;

  const ScannerState({
    this.detectedIngredients = const [],
    this.isScanning = false,
    this.matchedRecipes = const [],
    this.isMatching = false,
    this.only100PercentMatch = false,
  });

  ScannerState copyWith({
    List<String>? detectedIngredients,
    bool? isScanning,
    List<Recipe>? matchedRecipes,
    bool? isMatching,
    bool? only100PercentMatch,
  }) {
    return ScannerState(
      detectedIngredients: detectedIngredients ?? this.detectedIngredients,
      isScanning: isScanning ?? this.isScanning,
      matchedRecipes: matchedRecipes ?? this.matchedRecipes,
      isMatching: isMatching ?? this.isMatching,
      only100PercentMatch: only100PercentMatch ?? this.only100PercentMatch,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() {
    // Hydrate the pantry from local storage so scanned ingredients
    // survive app restarts and Home can show "You Can Make Now".
    Future.microtask(() => _hydrateFromPantry());
    return const ScannerState();
  }

  Future<void> _hydrateFromPantry() async {
    final repo = ref.read(pantryRepositoryProvider);
    var pantry = await repo.fetchPantry();

    // One-time cleanup for legacy auto-seeded produce bundle
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleaned =
          prefs.getBool('sprout_pantry_cleaned_starter_seed_v1') ?? false;
      if (!cleaned) {
        await prefs.setBool('sprout_pantry_cleaned_starter_seed_v1', true);
        final defaultSeed = ScannerRepository.presetBundles['Fresh Produce']!;
        if (pantry.length == defaultSeed.length &&
            pantry.every((item) => defaultSeed.contains(item.toLowerCase()))) {
          await repo.clear();
          pantry = [];
        }
      }
    } catch (_) {}

    state = state.copyWith(detectedIngredients: pantry);
    if (pantry.isNotEmpty) {
      await findMatches();
    } else {
      state = state.copyWith(matchedRecipes: const []);
    }
  }

  void _savePantry() {
    ref.read(pantryRepositoryProvider).addItems(state.detectedIngredients).then(
      (persisted) {
        state = state.copyWith(detectedIngredients: persisted);
      },
    );
  }

  void addIngredient(String name) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isNotEmpty && !state.detectedIngredients.contains(trimmed)) {
      state = state.copyWith(
        detectedIngredients: [...state.detectedIngredients, trimmed],
      );
      _savePantry();
    }
  }

  void removeIngredient(String name) {
    final updated = state.detectedIngredients.where((i) => i != name).toList();
    state = state.copyWith(
      detectedIngredients: updated,
      matchedRecipes: updated.isEmpty ? const [] : state.matchedRecipes,
    );
    ref.read(pantryRepositoryProvider).removeItem(name);
  }

  void setIngredients(List<String> list) {
    final cleaned = list
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    state = state.copyWith(detectedIngredients: cleaned);
    ref.read(pantryRepositoryProvider).clear().then((_) {
      if (cleaned.isNotEmpty) {
        ref.read(pantryRepositoryProvider).addItems(cleaned);
      }
    });
  }

  void clearIngredients() {
    state = state.copyWith(
      detectedIngredients: const [],
      matchedRecipes: const [],
    );
    ref.read(pantryRepositoryProvider).clear();
  }

  void toggle100PercentMatch() {
    state = state.copyWith(only100PercentMatch: !state.only100PercentMatch);
    findMatches();
  }

  Future<void> findMatches({int? maxTime, String? cuisine}) async {
    if (state.detectedIngredients.isEmpty) {
      state = state.copyWith(matchedRecipes: const [], isMatching: false);
      return;
    }
    state = state.copyWith(isMatching: true);
    final repo = ref.read(recipeRepositoryProvider);

    // Merge active pantry staples if enabled
    final staplesState = ref.read(pantryStaplesProvider).value;
    final List<String> effectiveIngredients;
    if (staplesState != null &&
        staplesState.isEnabled &&
        staplesState.staples.isNotEmpty) {
      final combined = {...state.detectedIngredients, ...staplesState.staples};
      effectiveIngredients = combined.toList();
    } else {
      effectiveIngredients = state.detectedIngredients;
    }

    var results = await repo.matchRecipes(
      userIngredients: effectiveIngredients,
      maxTime: maxTime,
      cuisineFilter: cuisine,
    );

    if (state.only100PercentMatch) {
      results = results.where((r) => r.missingIngredients.isEmpty).toList();
    }

    state = state.copyWith(matchedRecipes: results, isMatching: false);
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);

// Cook History State
class CookHistoryNotifier extends AsyncNotifier<List<CookHistoryItem>> {
  @override
  Future<List<CookHistoryItem>> build() async {
    final repo = ref.watch(savedRepositoryProvider);
    return repo.fetchCookHistory();
  }

  Future<void> recordCook(
    Recipe recipe, {
    int rating = 0,
    String difficulty = '',
  }) async {
    final repo = ref.read(savedRepositoryProvider);
    final item = await repo.recordCookHistory(
      recipe,
      rating: rating,
      difficulty: difficulty,
    );
    final current = state.value ?? [];
    state = AsyncData([item, ...current]);
  }
}

final cookHistoryProvider =
    AsyncNotifierProvider<CookHistoryNotifier, List<CookHistoryItem>>(
      CookHistoryNotifier.new,
    );

// Interactive Shopping List State
class ShoppingListNotifier extends AsyncNotifier<List<ShoppingItem>> {
  @override
  Future<List<ShoppingItem>> build() async {
    final repo = ref.watch(shoppingRepositoryProvider);
    return repo.fetchItems();
  }

  Future<void> addItems(List<String> names, {String? recipeTitle}) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final updated = await repo.addItems(names, recipeTitle: recipeTitle);
    state = AsyncData(updated);
  }

  Future<void> addItem(String name, {String? recipeTitle}) async {
    await addItems([name], recipeTitle: recipeTitle);
  }

  Future<void> toggleBought(String id) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final updated = await repo.toggleBought(id);
    state = AsyncData(updated);
  }

  Future<void> removeItem(String id) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final updated = await repo.removeItem(id);
    state = AsyncData(updated);
  }

  Future<void> clearBought() async {
    final repo = ref.read(shoppingRepositoryProvider);
    final updated = await repo.clearBought();
    state = AsyncData(updated);
  }
}

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>(
      ShoppingListNotifier.new,
    );

// ─────────────────────────────────────────────────────────────
// Pantry — persisted ingredients powering "You Can Make Now"
// ─────────────────────────────────────────────────────────────
class PantryNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final repo = ref.watch(pantryRepositoryProvider);
    return repo.fetchPantry();
  }

  Future<void> addItems(List<String> names) async {
    final repo = ref.read(pantryRepositoryProvider);
    state = AsyncData(await repo.addItems(names));
  }

  Future<void> removeItem(String name) async {
    final repo = ref.read(pantryRepositoryProvider);
    state = AsyncData(await repo.removeItem(name));
  }

  Future<void> clear() async {
    final repo = ref.read(pantryRepositoryProvider);
    state = AsyncData(await repo.clear());
  }
}

final pantryProvider = AsyncNotifierProvider<PantryNotifier, List<String>>(
  PantryNotifier.new,
);

/// Recipes the user can cook right now: at least one matched
/// ingredient and no missing ingredients, ranked by match %.
final cookableNowProvider = FutureProvider<List<Recipe>>((ref) async {
  final pantry = await ref.watch(pantryProvider.future);
  if (pantry.isEmpty) return [];
  final repo = ref.watch(recipeRepositoryProvider);
  final staplesState = ref.watch(pantryStaplesProvider).value;
  final effective =
      (staplesState != null &&
          staplesState.isEnabled &&
          staplesState.staples.isNotEmpty)
      ? {...pantry, ...staplesState.staples}.toList()
      : pantry;
  final matched = await repo.matchRecipes(userIngredients: effective);
  final cookable = matched.where((r) => r.missingIngredients.isEmpty).toList();
  cookable.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
  return cookable;
});

// ─────────────────────────────────────────────────────────────
// Active Cook Session — resume cooking where you left off
// ─────────────────────────────────────────────────────────────
class CookSessionNotifier extends AsyncNotifier<CookSession?> {
  @override
  Future<CookSession?> build() async {
    final repo = ref.watch(cookSessionRepositoryProvider);
    return repo.fetchSession();
  }

  Future<void> saveProgress(Recipe recipe, int step) async {
    final repo = ref.read(cookSessionRepositoryProvider);
    final session = CookSession(recipe: recipe, currentStep: step);
    await repo.saveSession(session);
    state = AsyncData(session);
  }

  Future<void> clear() async {
    final repo = ref.read(cookSessionRepositoryProvider);
    await repo.clearSession();
    state = const AsyncData(null);
  }
}

final cookSessionProvider =
    AsyncNotifierProvider<CookSessionNotifier, CookSession?>(
      CookSessionNotifier.new,
    );

// ─────────────────────────────────────────────────────────────
// Weekly Meal Planner State & Grocery Aggregator
// ─────────────────────────────────────────────────────────────
class MealPlanNotifier extends AsyncNotifier<List<MealPlanItem>> {
  @override
  Future<List<MealPlanItem>> build() async {
    final repo = ref.watch(mealPlanRepositoryProvider);
    return repo.fetchMealPlan();
  }

  Future<void> addOrUpdateMeal({
    required int dayOfWeek,
    required MealType mealType,
    required Recipe recipe,
    String? note,
  }) async {
    final repo = ref.read(mealPlanRepositoryProvider);
    final item = MealPlanItem(
      id: '${dayOfWeek}_${mealType.name}_${DateTime.now().millisecondsSinceEpoch}',
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      recipe: recipe,
      note: note,
      createdAt: DateTime.now(),
    );
    final updated = await repo.addOrUpdateItem(item);
    state = AsyncData(updated);
  }

  Future<void> removeMeal(String id) async {
    final repo = ref.read(mealPlanRepositoryProvider);
    final updated = await repo.removeItem(id);
    state = AsyncData(updated);
  }

  Future<void> clearWeek() async {
    final repo = ref.read(mealPlanRepositoryProvider);
    final updated = await repo.clearWeek();
    state = AsyncData(updated);
  }

  /// Exports missing ingredients for scheduled meals into the Interactive Shopping List.
  /// If [forDay] is provided, exports only for that day (1-7), otherwise for the whole week.
  Future<int> exportToShoppingList({int? forDay}) async {
    final items = state.value ?? [];
    final targetItems = forDay != null
        ? items.where((i) => i.dayOfWeek == forDay).toList()
        : items;
    if (targetItems.isEmpty) return 0;

    final pantry = await ref.read(pantryRepositoryProvider).fetchPantry();
    final staples = await ref.read(pantryRepositoryProvider).fetchStaples();
    final owned = {...pantry, ...staples}.map((e) => e.toLowerCase()).toSet();

    final needed = <String>{};
    for (final meal in targetItems) {
      for (final ing in meal.recipe.cleanedIngredients) {
        final clean = ing.trim().toLowerCase();
        if (clean.isNotEmpty &&
            !owned.any((o) => clean.contains(o) || o.contains(clean))) {
          needed.add(clean);
        }
      }
    }

    // Fallback: If pantry already covers everything, export recipe ingredients directly
    if (needed.isEmpty) {
      for (final meal in targetItems) {
        needed.addAll(meal.recipe.cleanedIngredients);
      }
    }

    if (needed.isNotEmpty) {
      final label = forDay != null
          ? 'Meal Plan (Day $forDay)'
          : 'Weekly Meal Plan';
      await ref
          .read(shoppingListProvider.notifier)
          .addItems(needed.toList(), recipeTitle: label);
    }
    return needed.length;
  }
}

final mealPlanProvider =
    AsyncNotifierProvider<MealPlanNotifier, List<MealPlanItem>>(
      MealPlanNotifier.new,
    );
