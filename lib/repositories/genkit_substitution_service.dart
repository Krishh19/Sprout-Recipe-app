import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

import '../../core/config.dart';
import '../models/substitution_model.dart';
import '../models/substitution_schema.dart';
import 'substitution_service.dart';

/// Genkit-backed culinary substitutions service using Genkit Dart 1.0.
/// Preserves the existing domain model, exact model identifier (`gemini-3.8-flash`),
/// and existing prompt intent while enforcing typed structured output.
class GenkitSubstitutionService implements SubstitutionService {
  final Genkit _ai;
  final String _apiKey;

  // Cached Genkit instance to avoid recreating framework objects on repeated calls
  static Genkit? _cachedGenkit;
  static String? _cachedApiKey;

  static Genkit _getOrCreateGenkit(String apiKey) {
    if (_cachedGenkit == null || _cachedApiKey != apiKey) {
      _cachedApiKey = apiKey;
      _cachedGenkit = Genkit(
        plugins: [googleAI(apiKey: apiKey)],
        isDevEnv: false,
        promptDir: null,
      );
    }
    return _cachedGenkit!;
  }

  GenkitSubstitutionService({Genkit? ai, String? apiKey})
    : _apiKey = apiKey ?? AppConfig.geminiApiKey,
      _ai = ai ?? _getOrCreateGenkit(apiKey ?? AppConfig.geminiApiKey);

  @override
  Future<List<SubstitutionModel>> getSubstitutions({
    required List<String> missingIngredients,
    required String recipeTitle,
  }) async {
    if (missingIngredients.isEmpty) return [];

    // Check curated offline defaults first
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

    // If API key is not configured or all items were matched offline, provide smart fallbacks
    if (_apiKey.isEmpty || unhandled.isEmpty) {
      for (var u in unhandled) {
        resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
      }
      return resolved;
    }

    try {
      final prompt =
          '''
You are Chef Sprout, a culinary substitutions specialist for the Sprout cooking app.
Suggest smart, accessible culinary substitutions for the following missing ingredients for the dish "$recipeTitle":
Missing ingredients: ${unhandled.join(', ')}
''';

      final response = await _ai.generate<SubstitutionListOutput, dynamic>(
        model: googleAI.gemini('gemini-3.8-flash'),
        prompt: prompt,
        outputSchema: SubstitutionListOutput.$schema,
      );

      final output = response.output;
      if (output != null && output.substitutions.isNotEmpty) {
        final mapped = mapAndValidateSubstitutions(
          output.substitutions,
          unhandled,
          recipeTitle: recipeTitle,
        );
        resolved.addAll(mapped);
      } else {
        // Fallback: try parsing JSON from response.text if schema output was null
        final text = response.text.trim();
        final parsedFromText = parseTextJsonFallback(text, unhandled);
        if (parsedFromText.isNotEmpty) {
          resolved.addAll(parsedFromText);
        } else {
          for (var u in unhandled) {
            resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
          }
        }
      }
    } catch (e) {
      // Safe error logging without exposing API key, prompt payload, or sensitive internals
      debugPrint('Genkit substitutions provider error: ${e.runtimeType}');
      // Graceful fallback to smart culinary heuristics
      for (var u in unhandled) {
        resolved.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
      }
    }

    return resolved;
  }

  /// Validates and maps typed schema outputs into the Sprout domain model
  static List<SubstitutionModel> mapAndValidateSubstitutions(
    List<SubstitutionOutputItem> items,
    List<String> unhandled, {
    String recipeTitle = '',
  }) {
    final result = <SubstitutionModel>[];
    final coveredIngredients = <String>{};

    for (final item in items) {
      final orig = item.originalIngredient.trim();
      final sub = item.substitute.trim();
      final tip = item.culinaryTip.trim();
      final rationale = item.rationale?.trim();

      // Enforce valid required fields
      if (orig.isNotEmpty && sub.isNotEmpty) {
        result.add(
          SubstitutionModel(
            originalIngredient: orig,
            substitute: sub,
            culinaryTip: tip.isNotEmpty ? tip : 'Use in equal proportion.',
            rationale: rationale != null && rationale.isNotEmpty
                ? rationale
                : null,
          ),
        );
        coveredIngredients.add(orig.toLowerCase());
      }
    }

    // Ensure all requested unhandled ingredients have a substitution
    for (var u in unhandled) {
      final lower = u.trim().toLowerCase();
      if (!coveredIngredients.any(
        (c) => c.contains(lower) || lower.contains(c),
      )) {
        result.add(SubstitutionService.createSmartFallback(u, recipeTitle: recipeTitle));
      }
    }

    return result;
  }

  /// Safe text-based JSON recovery if typed output is empty
  static List<SubstitutionModel> parseTextJsonFallback(
    String text,
    List<String> unhandled,
  ) {
    if (text.isEmpty) return [];
    try {
      final startIndex = text.indexOf('[');
      final endIndex = text.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonSub = text.substring(startIndex, endIndex + 1);
        final List<dynamic> decoded = jsonDecode(jsonSub);
        return decoded
            .map((e) => SubstitutionModel.fromJson(e as Map<String, dynamic>))
            .where(
              (m) => m.originalIngredient.isNotEmpty && m.substitute.isNotEmpty,
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
