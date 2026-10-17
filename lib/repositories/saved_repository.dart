import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/supabase_client.dart';
import '../../models/collection.dart';
import '../../models/cook_history_item.dart';
import '../../models/recipe.dart';

class SavedRepository {
  static const String _offlineSavedKey = 'sprout_offline_saved_recipes';
  static const String _offlineHistoryKey = 'sprout_offline_cook_history';
  static const String _offlineCollectionsKey = 'sprout_offline_collections';

  // Toggle favorite recipe
  Future<bool> toggleFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final savedJsonList = prefs.getStringList(_offlineSavedKey) ?? [];

    final existingIndex = savedJsonList.indexWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['id'] == recipe.id || decoded['title'] == recipe.title;
      } catch (_) {
        return false;
      }
    });

    final isCurrentlySaved = existingIndex >= 0;

    if (isCurrentlySaved) {
      savedJsonList.removeAt(existingIndex);
    } else {
      savedJsonList.add(jsonEncode(recipe.copyWith(isSaved: true).toJson()));
    }

    await prefs.setStringList(_offlineSavedKey, savedJsonList);

    // Sync with Supabase if online
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        if (isCurrentlySaved) {
          await SupabaseService.client
              .from('saved_recipes')
              .delete()
              .eq('user_id', user.id)
              .eq('recipe_id', recipe.id);
        } else {
          await SupabaseService.client.from('saved_recipes').upsert({
            'user_id': user.id,
            'recipe_id': recipe.id,
          });
        }
      }
    } catch (e) {
      debugPrint('Sync favorite with Supabase: $e');
    }

    return !isCurrentlySaved;
  }

  // Fetch all saved recipes
  Future<List<Recipe>> fetchSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJsonList = prefs.getStringList(_offlineSavedKey) ?? [];

    List<Recipe> localRecipes = [];
    for (var str in savedJsonList) {
      try {
        localRecipes.add(Recipe.fromJson(jsonDecode(str), isSaved: true));
      } catch (_) {}
    }

    // Try merging with Supabase
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final res = await SupabaseService.client
            .from('saved_recipes')
            .select('recipes (*)')
            .eq('user_id', user.id);

        if (res.isNotEmpty) {
          final cloudRecipes = (res as List)
              .map((e) => Recipe.fromJson(e['recipes'], isSaved: true))
              .toList();

          // Merge without duplicates
          for (var r in cloudRecipes) {
            if (!localRecipes.any((l) => l.id == r.id)) {
              localRecipes.add(r);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('fetchSavedRecipes Supabase error: $e');
    }

    return localRecipes;
  }

  // Record completed cooking session
  Future<CookHistoryItem> recordCookHistory(Recipe recipe, {int rating = 0, String difficulty = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_offlineHistoryKey) ?? [];

    final item = CookHistoryItem(
      id: 'cook-${DateTime.now().millisecondsSinceEpoch}',
      recipeId: recipe.id,
      recipeTitle: recipe.title,
      recipeImageUrl: recipe.imageUrl,
      cuisine: recipe.cuisine,
      totalTimeMins: recipe.totalTimeMins,
      cookedAt: DateTime.now(),
      rating: rating,
      difficulty: difficulty,
    );

    history.insert(0, jsonEncode(item.toJson()));
    await prefs.setStringList(_offlineHistoryKey, history);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client.from('cook_history').insert({
          'user_id': user.id,
          'recipe_id': recipe.id,
        });
      }
    } catch (e) {
      debugPrint('recordCookHistory Supabase error: $e');
    }

    return item;
  }

  // Fetch cook history
  Future<List<CookHistoryItem>> fetchCookHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_offlineHistoryKey) ?? [];
    List<CookHistoryItem> items = [];
    for (var str in history) {
      try {
        items.add(CookHistoryItem.fromJson(jsonDecode(str)));
      } catch (_) {}
    }

    // Merge with Supabase if online
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final res = await SupabaseService.client
            .from('cook_history')
            .select('id, created_at, recipes (*)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          for (var row in res as List) {
            final recipeData = row['recipes'];
            if (recipeData != null) {
              final remoteId = row['id']?.toString() ?? '';
              if (!items.any((it) => it.id == remoteId || it.recipeId == recipeData['id']?.toString())) {
                items.add(CookHistoryItem(
                  id: remoteId,
                  recipeId: recipeData['id']?.toString() ?? '',
                  recipeTitle: recipeData['title'] ?? 'Delicious Dish',
                  recipeImageUrl: recipeData['image_url'],
                  cuisine: recipeData['cuisine'] ?? 'Indian',
                  totalTimeMins: (recipeData['total_time_mins'] as num?)?.toInt() ?? 30,
                  cookedAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('fetchCookHistory Supabase error: $e');
    }

    items.sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    return items;
  }

  // Get cooked count
  Future<int> getCookedCount() async {
    final items = await fetchCookHistory();
    return items.length;
  }

  // Fetch collections
  Future<List<RecipeCollection>> fetchCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final colls = prefs.getStringList(_offlineCollectionsKey);

    if (colls == null || colls.isEmpty) {
      // Default initial collections
      final defaultCollections = [
        RecipeCollection(
          id: 'col-1',
          userId: 'local',
          name: 'Weeknight Dinners',
          description: 'Quick & comforting 30-min dishes',
          icon: 'flash',
          recipeCount: 0,
          createdAt: DateTime.now(),
        ),
        RecipeCollection(
          id: 'col-2',
          userId: 'local',
          name: 'High Protein',
          description: 'Paneer, dals, and powerhouse meals',
          icon: 'arm',
          recipeCount: 0,
          createdAt: DateTime.now(),
        ),
      ];
      final jsonList = defaultCollections.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_offlineCollectionsKey, jsonList);
      return defaultCollections;
    }

    return colls.map((c) => RecipeCollection.fromJson(jsonDecode(c))).toList();
  }

  // Create new collection
  Future<RecipeCollection> createCollection(String name, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final colls = await fetchCollections();

    final newColl = RecipeCollection(
      id: 'col-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      name: name,
      description: description,
      icon: 'bookmark',
      recipeCount: 0,
      createdAt: DateTime.now(),
    );

    colls.add(newColl);
    final jsonList = colls.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_offlineCollectionsKey, jsonList);

    return newColl;
  }

  // Fetch recipes belonging to a specific collection
  Future<List<Recipe>> fetchRecipesForCollection(String collectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sprout_collection_${collectionId}_recipes';
    final jsonList = prefs.getStringList(key) ?? [];
    List<Recipe> recipes = [];
    for (var str in jsonList) {
      try {
        recipes.add(Recipe.fromJson(jsonDecode(str), isSaved: true));
      } catch (_) {}
    }
    return recipes;
  }

  // Add recipe to collection
  Future<void> addRecipeToCollection(String collectionId, Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sprout_collection_${collectionId}_recipes';
    final jsonList = prefs.getStringList(key) ?? [];
    final alreadyExists = jsonList.any((it) {
      try {
        return jsonDecode(it)['id'] == recipe.id;
      } catch (_) {
        return false;
      }
    });
    if (!alreadyExists) {
      jsonList.add(jsonEncode(recipe.copyWith(isSaved: true).toJson()));
      await prefs.setStringList(key, jsonList);
    }
  }

  // Remove recipe from collection
  Future<void> removeRecipeFromCollection(String collectionId, String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sprout_collection_${collectionId}_recipes';
    final jsonList = prefs.getStringList(key) ?? [];
    jsonList.removeWhere((it) {
      try {
        return jsonDecode(it)['id'] == recipeId;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(key, jsonList);
  }
}
