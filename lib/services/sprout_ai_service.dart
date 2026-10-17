import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/nutrition_info.dart';
import '../models/substitution_model.dart';

/// Secure client-side bridge for Sprout AI services.
/// All heavy AI model calls (Groq Qwen 3.8 27B and Gemini) are handled server-side
/// inside the Supabase Edge Function 'sprout-ai', protecting private API keys from
/// APK decompilation or client reverse engineering.
class SproutAiService {
  static final SproutAiService _instance = SproutAiService._internal();
  factory SproutAiService() => _instance;
  SproutAiService._internal();

  SupabaseClient? get _client {
    try {
      return SupabaseService.client;
    } catch (_) {
      return null;
    }
  }

  /// Calculates nutritional breakdown per serving via Supabase Edge Function 'sprout-ai'.
  Future<NutritionInfo?> getNutrition({
    required String title,
    required String cuisine,
    required int servings,
    required List<String> ingredients,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.functions.invoke(
        'sprout-ai',
        body: {
          'task': 'nutrition',
          'data': {
            'title': title,
            'cuisine': cuisine,
            'servings': servings,
            'ingredients': ingredients,
          },
        },
      ).timeout(const Duration(seconds: 20));

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          final nutritionMap = data['data'] as Map<String, dynamic>;
          return NutritionInfo.fromJson({
            ...nutritionMap,
            'is_ai_estimated': true,
          });
        }
      }
    } catch (e) {
      debugPrint('SproutAiService.getNutrition edge function warning: $e');
    }
    return null;
  }

  /// Translates a recipe between Hindi and English via Supabase Edge Function 'sprout-ai'.
  Future<Map<String, dynamic>?> translateRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> instructions,
    required String targetLanguage,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.functions.invoke(
        'sprout-ai',
        body: {
          'task': 'translate',
          'data': {
            'title': title,
            'description': description,
            'ingredients': ingredients,
            'instructions': instructions,
            'target_language': targetLanguage,
          },
        },
      ).timeout(const Duration(seconds: 25));

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('SproutAiService.translateRecipe edge function warning: $e');
    }
    return null;
  }

  /// Recommends culinary substitutions for missing ingredients via Supabase Edge Function 'sprout-ai'.
  Future<List<SubstitutionModel>?> getSubstitutions({
    required String recipeTitle,
    required List<String> missingIngredients,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.functions.invoke(
        'sprout-ai',
        body: {
          'task': 'substitutions',
          'data': {
            'recipe_title': recipeTitle,
            'missing_ingredients': missingIngredients,
          },
        },
      ).timeout(const Duration(seconds: 20));

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'] as Map<String, dynamic>;
          final list = payload['substitutions'] as List?;
          if (list != null) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((m) => SubstitutionModel.fromJson(m))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('SproutAiService.getSubstitutions edge function warning: $e');
    }
    return null;
  }

  /// Analyzes a food/groceries image via Supabase Edge Function 'sprout-ai'
  /// using server-side Gemini multimodal vision.
  Future<List<String>?> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final base64Image = base64Encode(imageBytes);
      final response = await client.functions.invoke(
        'sprout-ai',
        body: {
          'task': 'vision',
          'data': {
            'image_base64': base64Image,
            'mime_type': mimeType,
          },
        },
      ).timeout(const Duration(seconds: 25));

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'] as Map<String, dynamic>;
          final list = payload['ingredients'] as List?;
          if (list != null) {
            return list.map((e) => e.toString().toLowerCase().trim()).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('SproutAiService.analyzeImage edge function warning: $e');
    }
    return null;
  }
}
