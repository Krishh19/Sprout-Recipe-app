import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/supabase_client.dart';
import '../design/sprout_ingredient_formatter.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class ShoppingRepository {
  static const String _key = 'sprout_offline_shopping_list';

  Future<List<ShoppingItem>> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    List<ShoppingItem> items = [];
    for (var s in list) {
      try {
        items.add(ShoppingItem.fromJson(jsonDecode(s)));
      } catch (_) {}
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final res = await SupabaseService.client
            .from('shopping_list')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (res.isNotEmpty) {
          for (var r in res as List) {
            final remoteId = r['id']?.toString() ?? '';
            if (!items.any((it) => it.id == remoteId)) {
              items.add(ShoppingItem.fromJson(r));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('fetchShoppingList Supabase error: $e');
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<ShoppingItem>> addItems(List<String> names, {String? recipeTitle}) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await fetchItems();

    final cleanTitle = recipeTitle != null && recipeTitle.isNotEmpty
        ? RecipeTitleCleaner.clean(recipeTitle).displayTitle
        : null;

    final newItems = <ShoppingItem>[];
    for (var rawName in names) {
      if (rawName.trim().isEmpty) continue;
      final parsed = SproutIngredientFormatter.parseIngredient(rawName);
      final primaryName = parsed.primaryName.trim();
      if (primaryName.isEmpty) continue;

      // Duplicate detection & merging for unbought items
      final existingIdx = items.indexWhere((it) =>
          it.name.toLowerCase() == primaryName.toLowerCase() && !it.isBought);

      if (existingIdx != -1) {
        final existing = items[existingIdx];
        final existingRecipe = existing.recipeTitle;
        final alreadyLinked = existingRecipe != null &&
            cleanTitle != null &&
            existingRecipe.toLowerCase().contains(cleanTitle.toLowerCase());

        String? mergedRecipe = existingRecipe;
        if (cleanTitle != null && !alreadyLinked) {
          mergedRecipe = existingRecipe == null || existingRecipe.isEmpty
              ? cleanTitle
              : '$existingRecipe, $cleanTitle';
        }

        // Merge quantities if units are compatible
        String mergedQuantity = existing.displayQuantity ?? '';
        double? mergedAmount;
        if (existing.numericAmount != null &&
            parsed.numericAmount != null &&
            existing.unit != null &&
            existing.unit == parsed.unit) {
          mergedAmount = existing.numericAmount! + parsed.numericAmount!;
          mergedQuantity = '${SproutIngredientFormatter.formatCombinedQuantity(mergedAmount, existing.unit)} total';
        } else if (parsed.displayQuantity.isNotEmpty &&
            parsed.displayQuantity != 'As needed') {
          if (mergedQuantity.isNotEmpty && mergedQuantity != 'As needed') {
            mergedQuantity = '$mergedQuantity + ${parsed.displayQuantity} total';
          } else {
            mergedQuantity = parsed.displayQuantity;
          }
        }

        items[existingIdx] = existing.copyWith(
          displayQuantity: mergedQuantity.isNotEmpty ? mergedQuantity : existing.displayQuantity,
          recipeTitle: mergedRecipe,
          recipeCount: alreadyLinked ? existing.recipeCount : existing.recipeCount + 1,
          numericAmount: mergedAmount ?? existing.numericAmount,
        );
        continue;
      }

      final item = ShoppingItem(
        id: 'shop-${DateTime.now().microsecondsSinceEpoch}-${newItems.length}',
        name: primaryName,
        displayQuantity: parsed.displayQuantity,
        recipeTitle: cleanTitle,
        recipeCount: 1,
        category: parsed.category,
        numericAmount: parsed.numericAmount,
        unit: parsed.unit,
        isBought: false,
        createdAt: DateTime.now(),
      );
      newItems.add(item);
      items.insert(0, item);
    }

    final jsonList = items.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_key, jsonList);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null && newItems.isNotEmpty) {
        for (var it in newItems) {
          await SupabaseService.client.from('shopping_list').insert({
            'id': it.id,
            'user_id': user.id,
            'name': it.name,
            'recipe_title': it.recipeTitle,
            'is_bought': false,
          });
        }
      }
    } catch (e) {
      debugPrint('addShoppingItems Supabase error: $e');
    }

    return items;
  }

  Future<List<ShoppingItem>> toggleBought(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await fetchItems();
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = items[index].copyWith(isBought: !items[index].isBought);
      items[index] = updated;
      final jsonList = items.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_key, jsonList);

      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client
              .from('shopping_list')
              .update({'is_bought': updated.isBought})
              .eq('id', id)
              .eq('user_id', user.id);
        }
      } catch (e) {
        debugPrint('toggleShoppingItem Supabase error: $e');
      }
    }
    return items;
  }

  Future<List<ShoppingItem>> removeItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await fetchItems();
    items.removeWhere((i) => i.id == id);
    final jsonList = items.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_key, jsonList);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('shopping_list')
            .delete()
            .eq('id', id)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('removeShoppingItem Supabase error: $e');
    }

    return items;
  }

  Future<List<ShoppingItem>> clearBought() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await fetchItems();
    items.removeWhere((i) => i.isBought);
    final jsonList = items.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_key, jsonList);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('shopping_list')
            .delete()
            .eq('is_bought', true)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('clearBoughtShoppingItems Supabase error: $e');
    }

    return items;
  }
}
