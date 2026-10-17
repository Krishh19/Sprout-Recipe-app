import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../models/nutrition_info.dart';
import '../models/recipe.dart';
import '../services/groq_service.dart';
import '../services/sprout_ai_service.dart';

class NutritionService {
  final String _apiKey;

  NutritionService({String? apiKey})
      : _apiKey = apiKey ?? AppConfig.geminiApiKey;

  Future<NutritionInfo> getNutrition(Recipe recipe) async {
    final cacheKey = 'sprout_nutrition_${recipe.slug ?? recipe.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        return NutritionInfo.fromJson(map);
      }
    } catch (e) {
      debugPrint('Nutrition cache read warning: $e');
    }

    // 1. Primary: Use secure Supabase Edge Function 'sprout-ai' (Groq Qwen 3.8 / Gemini server-side)
    try {
      final edgeNutrition = await SproutAiService().getNutrition(
        title: recipe.title,
        cuisine: recipe.cuisine,
        servings: recipe.servings > 0 ? recipe.servings : 4,
        ingredients: recipe.ingredients,
      );
      if (edgeNutrition != null) {
        _saveToCache(cacheKey, edgeNutrition);
        return edgeNutrition;
      }
    } catch (e) {
      debugPrint('Edge nutrition estimate error, falling back: $e');
    }

    // 2. Direct Groq API (if developer configured local key in environment)
    if (GroqService().isAvailable) {
      try {
        final prompt = '''
You are an expert nutritional scientist. Calculate the nutritional breakdown PER SERVING for this recipe:
Recipe: "${recipe.title}"
Cuisine: ${recipe.cuisine}
Default Servings: ${recipe.servings > 0 ? recipe.servings : 4}
Ingredients:
${recipe.ingredients.take(15).join('\n')}

Provide realistic culinary estimates for one average adult serving:
- calories (integer kcal)
- protein (integer grams)
- carbs (integer grams)
- fat (integer grams)
- fiber (integer grams)
- health_note (one punchy phrase under 8 words, e.g., "High in lean protein & potassium" or "Rich in dietary fiber & healthy fats")

Respond ONLY with this JSON schema:
{
  "calories": 420,
  "protein": 24,
  "carbs": 38,
  "fat": 16,
  "fiber": 6,
  "health_note": "High in lean protein & fiber"
}
''';
        final map = await GroqService().chatCompletionJson(
          messages: [
            {
              'role': 'system',
              'content': 'You are an expert nutritional scientist. Always return strictly valid JSON matching the schema.',
            },
            {'role': 'user', 'content': prompt},
          ],
        );

        if (map != null && map['calories'] != null) {
          final info = NutritionInfo.fromJson({
            ...map,
            'is_ai_estimated': true,
          });

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(cacheKey, jsonEncode(info.toJson()));
          } catch (_) {}

          return info;
        }
      } catch (e) {
        debugPrint('Groq nutrition estimate failed: $e');
      }
    }

    // Try Gemini 3.8 Flash if API key is present
    if (_apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-3.8-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.2,
          ),
        );

        final prompt = '''
You are an expert nutritional scientist. Calculate the nutritional breakdown PER SERVING for this recipe:
Recipe: "${recipe.title}"
Cuisine: ${recipe.cuisine}
Default Servings: ${recipe.servings > 0 ? recipe.servings : 4}
Ingredients:
${recipe.ingredients.take(15).join('\n')}

Provide realistic culinary estimates for one average adult serving:
- calories (integer kcal)
- protein (integer grams)
- carbs (integer grams)
- fat (integer grams)
- fiber (integer grams)
- health_note (one punchy phrase under 8 words, e.g., "High in lean protein & potassium" or "Rich in dietary fiber & healthy fats")

Respond ONLY with this JSON schema:
{
  "calories": 420,
  "protein": 24,
  "carbs": 38,
  "fat": 16,
  "fiber": 6,
  "health_note": "High in lean protein & fiber"
}
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) {
          final cleanJson = text.replaceAll(RegExp(r'^```json\s*|\s*```$'), '');
          final map = jsonDecode(cleanJson) as Map<String, dynamic>;
          final info = NutritionInfo.fromJson({
            ...map,
            'isAiEstimated': true,
          });

          // Save to cache
          _saveToCache(cacheKey, info);
          return info;
        }
      } catch (e) {
        debugPrint('Gemini 3.8 Flash Nutrition error, using culinary heuristic: $e');
      }
    }

    // Heuristic Fallback based on ingredients and cuisine
    final heuristic = calculateHeuristicNutrition(recipe);
    _saveToCache(cacheKey, heuristic);
    return heuristic;
  }

  Future<void> _saveToCache(String key, NutritionInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(info.toJson()));
    } catch (e) {
      debugPrint('Nutrition cache save warning: $e');
    }
  }

  static NutritionInfo calculateHeuristicNutrition(Recipe recipe) {
    final ingText = '${recipe.ingredients.join(' ')} ${recipe.title}'.toLowerCase();

    int protein = 8;
    int carbs = 25;
    int fat = 10;
    int fiber = 3;
    String healthNote = 'Balanced home-cooked meal';

    // Protein detection
    if (RegExp(r'\b(chicken|mutton|beef|pork|lamb|turkey)\b').hasMatch(ingText)) {
      protein += 24;
      fat += 8;
      healthNote = 'Rich in lean complete protein';
    } else if (RegExp(r'\b(fish|salmon|tuna|prawn|shrimp|seafood|crab)\b').hasMatch(ingText)) {
      protein += 20;
      fat += 5;
      healthNote = 'Rich in omega-3 and lean protein';
    } else if (RegExp(r'\b(paneer|tofu|egg|eggs)\b').hasMatch(ingText)) {
      protein += 15;
      fat += 10;
      healthNote = 'Good source of protein & calcium';
    } else if (RegExp(r'\b(dal|lentil|chana|chickpea|beans|rajma|moong|urad|toor)\b').hasMatch(ingText)) {
      protein += 14;
      fiber += 6;
      carbs += 18;
      healthNote = 'High in plant protein & dietary fiber';
    }

    // Carbs detection
    if (RegExp(r'\b(rice|biryani|pulao|pasta|spaghetti|penne|noodle|noodles)\b').hasMatch(ingText)) {
      carbs += 28;
    } else if (RegExp(r'\b(flour|roti|paratha|naan|bread|puri|wheat|maida)\b').hasMatch(ingText)) {
      carbs += 22;
    } else if (RegExp(r'\b(potato|potatoes|aloo|yam|corn)\b').hasMatch(ingText)) {
      carbs += 15;
    } else if (RegExp(r'\b(sugar|jaggery|honey|syrup|sweet|halwa|kheer)\b').hasMatch(ingText)) {
      carbs += 26;
      healthNote = 'Energy-dense dessert treat';
    }

    // Fat detection
    if (RegExp(r'\b(ghee|butter|oil|cream|cheese|mayonnaise|coconut milk)\b').hasMatch(ingText)) {
      fat += 9;
    }
    if (RegExp(r'\b(deep fry|fried|pakora|vada|bhajji|crispy)\b').hasMatch(ingText)) {
      fat += 12;
    }

    // Fiber & Micronutrients
    if (RegExp(r'\b(spinach|palak|methi|cabbage|broccoli|carrot|tomato|cucumber|salad|greens)\b').hasMatch(ingText)) {
      fiber += 4;
      if (healthNote == 'Balanced home-cooked meal') {
        healthNote = 'Rich in vitamins & dietary fiber';
      }
    }

    final totalCalories = (protein * 4) + (carbs * 4) + (fat * 9);

    return NutritionInfo(
      calories: totalCalories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      healthNote: healthNote,
      isAiEstimated: false,
    );
  }
}
