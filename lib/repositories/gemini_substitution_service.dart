import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/config.dart';
import '../models/substitution_model.dart';
import 'substitution_service.dart';

/// Legacy Gemini implementation using `package:google_generative_ai`.
/// Preserved for rollback safety and comparative verification.
class GeminiSubstitutionService implements SubstitutionService {
  final String _apiKey;

  GeminiSubstitutionService({String? apiKey})
    : _apiKey = apiKey ?? AppConfig.geminiApiKey;

  @override
  Future<List<SubstitutionModel>> getSubstitutions({
    required List<String> missingIngredients,
    required String recipeTitle,
  }) async {
    if (missingIngredients.isEmpty) return [];

    // Check offline defaults first
    final resolved = <SubstitutionModel>[];
    final unhandled = <String>[];

    for (var ing in missingIngredients) {
      final clean = ing.trim().toLowerCase();
      SubstitutionModel? matched;
      for (var entry in SubstitutionService.offlineSubstitutions.entries) {
        if (clean.contains(entry.key) || entry.key.contains(clean)) {
          matched = SubstitutionModel(
            originalIngredient: ing,
            substitute: entry.value.substitute,
            culinaryTip: entry.value.culinaryTip,
            rationale: entry.value.rationale,
          );
          break;
        }
      }
      if (matched != null) {
        resolved.add(matched);
      } else {
        unhandled.add(ing);
      }
    }

    // If Gemini key is not configured or all items were matched offline, provide smart fallbacks for remaining
    if (_apiKey.isEmpty || unhandled.isEmpty) {
      for (var u in unhandled) {
        resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
      }
      return resolved;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.8-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3,
        ),
      );

      final prompt =
          '''
You are Chef Sprout, a culinary substitutions specialist for the Sprout cooking app.
Suggest smart, accessible culinary substitutions for the following missing ingredients for the dish "$recipeTitle":
Missing ingredients: ${unhandled.join(', ')}

Return ONLY a valid JSON array of objects with the following schema:
[
  {
    "original_ingredient": "ingredient name",
    "substitute": "recommended substitution",
    "culinary_tip": "actionable tip on proportions or preparation method",
    "rationale": "why this swap works in this specific dish"
  }
]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      debugPrint('Gemini 3.8 Flash Substitutions response: $text');

      final startIndex = text.indexOf('[');
      final endIndex = text.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonSub = text.substring(startIndex, endIndex + 1);
        final List<dynamic> decoded = jsonDecode(jsonSub);
        final aiSubs = decoded
            .map((e) => SubstitutionModel.fromJson(e))
            .toList();
        resolved.addAll(aiSubs);
      } else {
        for (var u in unhandled) {
          resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
        }
      }
    } catch (e) {
      debugPrint('Gemini Substitutions error: $e');
      // Intelligent culinary fallback for unhandled ingredients
      for (var u in unhandled) {
        resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
      }
    }

    return resolved;
  }
}
