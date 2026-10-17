import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/config.dart';
import '../models/substitution_model.dart';
import '../services/groq_service.dart';
import '../services/sprout_ai_service.dart';
import 'substitution_service.dart';

/// High-speed Groq implementation using Qwen models (e.g. qwen/qwen3.8-27b)
/// for intelligent culinary ingredient substitutions, with seamless fallback to Gemini.
class GroqSubstitutionService implements SubstitutionService {
  final GeminiSubstitutionService _geminiFallback = GeminiSubstitutionService();

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

    if (unhandled.isEmpty) {
      return resolved;
    }

    // 1. Primary: Use secure Supabase Edge Function 'sprout-ai' (Groq Qwen 3.8 / Gemini server-side)
    try {
      final edgeSubs = await SproutAiService().getSubstitutions(
        recipeTitle: recipeTitle,
        missingIngredients: unhandled,
      );
      if (edgeSubs != null && edgeSubs.isNotEmpty) {
        resolved.addAll(edgeSubs);
        return resolved;
      }
    } catch (e) {
      debugPrint('Edge substitutions error, falling back: $e');
    }

    // 2. Direct Groq API (if developer configured local key in environment)
    if (GroqService().isAvailable) {
      try {
        final prompt = '''
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

        final text = await GroqService().chatCompletion(
          messages: [
            {
              'role': 'system',
              'content': 'You are an expert culinary scientist. Output strictly a JSON array without markdown formatting.',
            },
            {'role': 'user', 'content': prompt},
          ],
          model: AppConfig.groqModel,
          temperature: 0.3,
          maxTokens: 1024,
        );

        if (text != null && text.trim().isNotEmpty) {
          final cleanText = text.trim();
          final startIndex = cleanText.indexOf('[');
          final endIndex = cleanText.lastIndexOf(']');
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            final jsonSub = cleanText.substring(startIndex, endIndex + 1);
            final List<dynamic> decoded = jsonDecode(jsonSub);
            final aiSubs = decoded.map((e) => SubstitutionModel.fromJson(e)).toList();
            resolved.addAll(aiSubs);
            return resolved;
          }
        }
      } catch (e) {
        debugPrint('Groq substitutions exception: $e');
      }
    }

    // Fallback to Gemini if Groq is unavailable or failed
    try {
      final geminiSubs = await _geminiFallback.getSubstitutions(
        missingIngredients: unhandled,
        recipeTitle: recipeTitle,
      );
      resolved.addAll(geminiSubs);
    } catch (e) {
      debugPrint('Gemini substitutions fallback error: $e');
      for (var u in unhandled) {
        resolved.add(SubstitutionService.createSmartFallback(u));
      }
    }

    return resolved;
  }
}
