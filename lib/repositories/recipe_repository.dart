import 'package:flutter/foundation.dart';
import '../core/ingredient_matcher.dart';
import '../../core/supabase_client.dart';
import '../../models/recipe.dart';

class RecipeRepository {
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  /// Filters recipes to prevent mixing Hindi script cards into English experience
  static List<Recipe> filterByLocale(List<Recipe> recipes, {String languageCode = 'en'}) {
    if (languageCode == 'en') {
      return recipes.where((r) => !_devanagariRegex.hasMatch(r.title)).toList();
    }
    return recipes;
  }
  // Built-in curated recipes from Cleaned_Indian_Food_Dataset for offline fallback & instant start
  static final List<Recipe> fallbackRecipes = [
    const Recipe(
      id: 'fb-1',
      title: 'Masala Karela Recipe',
      description: 'Traditional Indian bitter gourd stir-fry packed with roasted spices, amchur, and golden onions.',
      ingredients: [
        '6 Karela (Bitter Gourd) - deseeded and sliced',
        '1 Onion - thinly sliced',
        '1 tbsp Red Chilli powder',
        '3 tbsp Gram flour (besan)',
        '2 tsp Cumin seeds (jeera)',
        '1 tbsp Coriander Powder (dhania)',
        '2 tsp Turmeric powder (haldi)',
        '1 tbsp Amchur (dry mango powder)',
        'Sunflower Oil - as required',
        'Salt - to taste',
      ],
      cleanedIngredients: [
        'karela',
        'onion',
        'red chilli powder',
        'besan',
        'cumin seeds',
        'coriander powder',
        'turmeric powder',
        'amchur',
        'oil',
        'salt',
      ],
      instructions: [
        'De-seed the karela and slice thinly without removing the nutrient-rich skin.',
        'Pressure cook the karela with 3 tbsp water, salt, and turmeric for 3 whistles.',
        'Heat sunflower oil in a heavy pan and add cumin seeds until fragrant.',
        'Add sliced onions and sauté until translucent and sweet.',
        'Stir in besan, red chilli, coriander, and amchur powder, then toss the cooked karela.',
        'Roast on medium flame until edges are crisp and aromatic. Serve hot with roti.',
      ],
      totalTimeMins: 45,
      cuisine: 'Indian',
      imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=800&q=80',
      servings: 1,
      rating: 4.8,
      reviewCount: 42,
    ),
    const Recipe(
      id: 'fb-2',
      title: 'Paneer Butter Masala',
      description: 'Velvety cottage cheese cubes simmered in a creamy, buttery tomato-cashew sauce with kasuri methi.',
      ingredients: [
        '250g Paneer - cut into cubes',
        '3 ripe Tomatoes - pureed',
        '2 Onions - finely chopped',
        '1 tbsp Ginger Garlic paste',
        '2 tbsp Butter',
        '1/4 cup Fresh Cream',
        '10 Cashews - soaked in warm water',
        '1 tsp Garam Masala',
        '1 tsp Kasuri Methi - crushed',
        'Salt and Red Chilli powder to taste',
      ],
      cleanedIngredients: [
        'paneer',
        'tomato',
        'onion',
        'ginger garlic paste',
        'butter',
        'fresh cream',
        'cashews',
        'garam masala',
        'kasuri methi',
        'salt',
      ],
      instructions: [
        'Soak cashews in warm water for 15 minutes, then blend into a smooth paste.',
        'Melt butter in a pan, add finely chopped onions, and sauté until golden brown.',
        'Add ginger-garlic paste and stir for 1 minute until fragrant.',
        'Pour in the tomato puree, salt, and chilli powder. Cook until oil separates.',
        'Stir in cashew paste, cream, and garam masala. Simmer on low flame for 4 minutes.',
        'Gently fold in paneer cubes and crushed kasuri methi. Simmer for 2 minutes and serve.',
      ],
      totalTimeMins: 30,
      cuisine: 'North Indian',
      imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80',
      servings: 1,
      rating: 4.9,
      reviewCount: 128,
    ),
    const Recipe(
      id: 'fb-3',
      title: 'Garlic Spinach Dal (Palak Dal)',
      description: 'Nutritious yellow lentils slow-cooked with fresh baby spinach and tempered with garlic, cumin, and ghee.',
      ingredients: [
        '1 cup Toor Dal (pigeon peas) - washed',
        '2 cups Fresh Spinach (palak) - chopped',
        '6 cloves Garlic - smashed',
        '1 Green Chilli - slit',
        '1 tsp Cumin seeds',
        '1/2 tsp Turmeric powder',
        '2 tbsp Ghee',
        'Salt to taste',
      ],
      cleanedIngredients: [
        'toor dal',
        'spinach',
        'garlic',
        'green chilli',
        'cumin seeds',
        'turmeric powder',
        'ghee',
        'salt',
      ],
      instructions: [
        'Pressure cook toor dal with turmeric and 2.5 cups of water until soft and mashable.',
        'In a pan, add chopped spinach with a splash of water and cook for 3 minutes until wilted.',
        'Combine cooked lentils and spinach; season with salt and simmer for 5 minutes.',
        'In a small tadka pan, heat ghee. Add cumin seeds, smashed garlic, and green chilli.',
        'Let garlic turn golden brown and fragrant, then pour the tempering immediately over the dal.',
        'Stir gently and serve hot with steamed basmati rice or parathas.',
      ],
      totalTimeMins: 25,
      cuisine: 'Indian',
      imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80',
      servings: 1,
      rating: 4.7,
      reviewCount: 64,
    ),
    const Recipe(
      id: 'fb-4',
      title: 'Crispy Aloo Jeera',
      description: 'Golden spiced potato cubes tossed in roasted cumin seeds, turmeric, and fresh cilantro.',
      ingredients: [
        '4 medium Potatoes - boiled and diced',
        '1.5 tbsp Cumin seeds (jeera)',
        '1 tbsp Mustard oil or Ghee',
        '1/2 tsp Turmeric powder',
        '1 tsp Coriander powder',
        '1 tsp Amchur powder',
        '2 tbsp Fresh Coriander - chopped',
        'Salt to taste',
      ],
      cleanedIngredients: [
        'potatoes',
        'cumin seeds',
        'oil',
        'turmeric powder',
        'coriander powder',
        'amchur',
        'coriander leaves',
        'salt',
      ],
      instructions: [
        'Boil, peel, and dice the potatoes into bite-sized cubes.',
        'Heat mustard oil or ghee in a pan until hot. Add cumin seeds and let them crackle.',
        'Add diced potatoes, turmeric, and salt. Toss well to coat evenly.',
        'Cook on medium-low heat for 8-10 minutes, tossing occasionally until a crisp golden crust forms.',
        'Sprinkle coriander powder and amchur powder. Toss for 1 more minute.',
        'Garnish with freshly chopped cilantro and serve warm.',
      ],
      totalTimeMins: 20,
      cuisine: 'North Indian',
      imageUrl: 'https://images.unsplash.com/photo-1569603375125-66663722b0c5?auto=format&fit=crop&w=800&q=80',
      servings: 1,
      rating: 4.6,
      reviewCount: 51,
    ),
  ];

  static const String _listColumns =
      'id,title,slug,description,cuisine,total_time_mins,image_url,servings,diet,ingredients,cleaned_ingredients,instructions,rating,review_count';

  static List<Recipe> parseRows(List<dynamic> rows) {
    final out = <Recipe>[];
    var skipped = 0;
    for (final row in rows) {
      try {
        out.add(Recipe.fromJson(row as Map<String, dynamic>));
      } catch (e) {
        skipped++;
        debugPrint('Skipping malformed recipe row: $e');
      }
    }
    if (skipped > 0) debugPrint('Skipped $skipped malformed recipe rows');
    return out;
  }

  Future<List<Recipe>> fetchTrendingRecipes({
    int limit = 12,
    String? diet,
  }) async {
    try {
      var q = SupabaseService.client
          .from('recipes')
          .select(_listColumns)
          .eq('image_status', 'verified');

      if (diet != null && diet.isNotEmpty) {
        q = q.eq('diet', diet);
      }

      // Calculate a daily deterministic offset so each day has fresh curated trending recipes
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final start = (dayOfYear * limit) % 300;
      final end = start + limit - 1;

      final res = await q.order('id').range(start, end);

      if (res.isNotEmpty) {
        final list = filterByLocale(parseRows(res));
        if (list.isNotEmpty) return list.take(limit).toList();
      }
    } catch (e) {
      debugPrint('fetchTrendingRecipes Supabase error: $e');
    }

    // Fallback to offline recipes if database cannot be queried
    final fallback = diet != null
        ? fallbackRecipes.where((r) => r.diet == diet).toList()
        : List<Recipe>.from(fallbackRecipes);
    return filterByLocale(fallback).take(limit).toList();
  }

  Future<List<Recipe>> fetchQuickRecipes({
    int minMinutes = 12,
    int maxMinutes = 30,
    int limit = 12,
    String? diet,
  }) async {
    try {
      var q = SupabaseService.client
          .from('recipes')
          .select(_listColumns)
          .eq('image_status', 'verified')
          .gte('total_time_mins', minMinutes)
          .lte('total_time_mins', maxMinutes);

      if (diet != null && diet.isNotEmpty) {
        q = q.eq('diet', diet);
      }

      // Daily rotation offset for quick recipes to maintain fresh daily inspiration
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final start = ((dayOfYear + 7) * limit) % 200;
      final end = start + limit - 1;

      final res = await q.order('total_time_mins', ascending: true).range(start, end);

      if (res.isNotEmpty) {
        final list = filterByLocale(parseRows(res));
        if (list.isNotEmpty) return list.take(limit).toList();
      }
    } catch (e) {
      debugPrint('fetchQuickRecipes Supabase error: $e');
    }

    final fallback = fallbackRecipes
        .where((r) => r.totalTimeMins <= maxMinutes && (diet == null || r.diet == diet))
        .toList();
    return filterByLocale(fallback).take(limit).toList();
  }

  /// Extracts natural language intent (time limits, diets, and clean search keywords).
  static Map<String, dynamic> parseSearchIntent(String rawQuery) {
    String query = rawQuery.toLowerCase().trim();
    int? extractedTime;
    final extractedDiets = <String>[];

    // Parse time limits (e.g. "under 30 mins", "in 15 min", "20 mins", "quick")
    final timeMatch = RegExp(r'(?:(?:under|in|within|less than)\s+)?(\d+)\s*(?:mins|minute|min|m\b)').firstMatch(query);
    if (timeMatch != null) {
      extractedTime = int.tryParse(timeMatch.group(1) ?? '');
      query = query.replaceAll(timeMatch.group(0)!, '').trim();
    } else if (query.contains('quick') || query.contains('fast')) {
      extractedTime = 30;
      query = query.replaceAll(RegExp(r'\b(quick|fast)\b'), '').trim();
    }

    // Parse diet keywords
    if (query.contains('vegan')) {
      extractedDiets.add('vegan');
      query = query.replaceAll('vegan', '').trim();
    } else if (query.contains('vegetarian') || query.contains('veg')) {
      extractedDiets.add('vegetarian');
      query = query.replaceAll(RegExp(r'\b(vegetarian|veg)\b'), '').trim();
    }

    return {
      'cleanQuery': query.replaceAll(RegExp(r'\s+'), ' ').trim(),
      'maxTime': extractedTime,
      'diets': extractedDiets,
    };
  }

  Future<List<Recipe>> searchRecipes({
    required String query,
    int? maxTime,
    String? cuisine,
    List<String>? diets,
    int page = 0,
    int pageSize = 20,
  }) async {
    final intent = parseSearchIntent(query);
    final cleanQuery = (intent['cleanQuery'] as String?) ?? query.trim();
    final effectiveMaxTime = maxTime ?? (intent['maxTime'] as int?);
    final intentDiets = intent['diets'] as List<String>?;
    final effectiveDiets = (diets != null && diets.isNotEmpty)
        ? diets
        : (intentDiets != null && intentDiets.isNotEmpty ? intentDiets : null);

    try {
      var queryBuilder = SupabaseService.client.from('recipes').select(_listColumns);

      if (cleanQuery.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('title', '%$cleanQuery%');
      }

      if (effectiveMaxTime != null) {
        queryBuilder = queryBuilder.lte('total_time_mins', effectiveMaxTime);
      }

      if (cuisine != null && cuisine.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('cuisine', '%$cuisine%');
      }

      if (effectiveDiets != null && effectiveDiets.isNotEmpty) {
        queryBuilder = queryBuilder.inFilter('diet', effectiveDiets);
      }

      final start = page * pageSize;
      final end = start + pageSize - 1;
      final res = await queryBuilder.order('title', ascending: true).range(start, end);
      return parseRows(res);
    } catch (e) {
      debugPrint('searchRecipes Supabase error: $e');
    }

    if (page > 0) return [];

    // Local semantic & multi-field relevance scoring fallback
    final lowerQuery = cleanQuery.toLowerCase();
    final filtered = fallbackRecipes.where((r) {
      final matchesQuery = lowerQuery.isEmpty ||
          r.title.toLowerCase().contains(lowerQuery) ||
          r.description.toLowerCase().contains(lowerQuery) ||
          r.cuisine.toLowerCase().contains(lowerQuery) ||
          r.cleanedIngredients.any((i) => i.toLowerCase().contains(lowerQuery));
      final matchesTime = effectiveMaxTime == null || r.totalTimeMins <= effectiveMaxTime;
      final matchesCuisine = cuisine == null || r.cuisine.toLowerCase().contains(cuisine.toLowerCase());
      final matchesDiet = effectiveDiets == null || effectiveDiets.isEmpty || effectiveDiets.contains(r.diet);
      return matchesQuery && matchesTime && matchesCuisine && matchesDiet;
    }).toList();

    // Rank by relevance if query provided, else rank contextually
    if (lowerQuery.isNotEmpty) {
      filtered.sort((a, b) {
        int scoreA = 0;
        int scoreB = 0;
        if (a.title.toLowerCase().contains(lowerQuery)) scoreA += 10;
        if (b.title.toLowerCase().contains(lowerQuery)) scoreB += 10;
        if (a.cuisine.toLowerCase().contains(lowerQuery)) scoreA += 5;
        if (b.cuisine.toLowerCase().contains(lowerQuery)) scoreB += 5;
        if (a.cleanedIngredients.any((i) => i.toLowerCase().contains(lowerQuery))) scoreA += 3;
        if (b.cleanedIngredients.any((i) => i.toLowerCase().contains(lowerQuery))) scoreB += 3;
        final comp = scoreB.compareTo(scoreA);
        if (comp != 0) return comp;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      final hour = DateTime.now().hour;
      filtered.sort((a, b) {
        int scoreA = 0;
        int scoreB = 0;
        if (hour >= 6 && hour < 11) {
          if (a.totalTimeMins <= 25) scoreA += 3;
          if (b.totalTimeMins <= 25) scoreB += 3;
        }
        scoreA += ((a.rating ?? 4.0) * 2).toInt();
        scoreB += ((b.rating ?? 4.0) * 2).toInt();
        final comp = scoreB.compareTo(scoreA);
        if (comp != 0) return comp;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    return filtered;
  }

  Future<Recipe?> fetchRecipeById(String id) async {
    try {
      final res = await SupabaseService.client
          .from('recipes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res != null) {
        return Recipe.fromJson(res);
      }
    } catch (e) {
      debugPrint('fetchRecipeById Supabase error: $e');
    }

    return fallbackRecipes.cast<Recipe?>().firstWhere(
      (r) => r?.id == id,
      orElse: () => null,
    );
  }

  Future<List<Recipe>> matchRecipes({
    required List<String> userIngredients,
    int? maxTime,
    String? cuisineFilter,
    int limit = 50,
  }) async {
    if (userIngredients.isEmpty) return [];

    final normUser = userIngredients.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();

    try {
      // Call PostgreSQL RPC function
      final res = await SupabaseService.client.rpc(
        'match_recipes',
        params: {
          'user_ingredients': userIngredients,
          'max_time': maxTime,
          'cuisine_filter': cuisineFilter,
          'limit_count': limit,
        },
      );

      if (res is List) {
        final parsed = parseRows(res);
        final validated = parsed.map((r) {
          final matchedList = r.cleanedIngredients.where((ing) {
            return normUser.any((u) => IngredientMatcher.isMatch(userItem: u, recipeIngredient: ing));
          }).toList();
          if (matchedList.isEmpty) return null;
          final missingList = r.cleanedIngredients.where((ing) => !matchedList.contains(ing)).toList();
          final pct = (matchedList.length / r.cleanedIngredients.length) * 100.0;
          return r.copyWith(
            matchedIngredients: matchedList,
            missingIngredients: missingList,
            matchPercentage: pct,
          );
        }).whereType<Recipe>().toList();
        if (validated.isNotEmpty) {
          validated.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
          return validated;
        }
      }
    } catch (e) {
      debugPrint('matchRecipes RPC Supabase error: $e');
    }

    // Client-side local matching fallback
    List<Recipe> matched = [];

    for (var r in fallbackRecipes) {
      final matchedList = r.cleanedIngredients.where((ing) {
        return normUser.any((u) => IngredientMatcher.isMatch(userItem: u, recipeIngredient: ing));
      }).toList();

      if (matchedList.isNotEmpty) {
        final missingList = r.cleanedIngredients
            .where((ing) => !matchedList.contains(ing))
            .toList();
        final pct = (matchedList.length / r.cleanedIngredients.length) * 100.0;

        matched.add(r.copyWith(
          matchedIngredients: matchedList,
          missingIngredients: missingList,
          matchPercentage: pct,
        ));
      }
    }

    matched.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return matched;
  }
}
