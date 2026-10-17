import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class GeminiSousChefService {
  static final GeminiSousChefService _instance = GeminiSousChefService._internal();
  factory GeminiSousChefService() => _instance;
  GeminiSousChefService._internal();

  final List<String> _candidateModels = [
    'gemini-flash-lite-latest',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
  ];

  /// Asks Chef Sprout a cooking question in the context of the current step and recipe.
  /// Returns a concise, conversational 1-2 sentence response suitable for TTS playback.
  Future<String?> askCookingQuestion({
    required String question,
    required String recipeTitle,
    required List<String> ingredients,
    required String currentStepText,
    required int stepNumber,
  }) async {
    if (AppConfig.geminiApiKey.isEmpty) {
      debugPrint('GeminiSousChef: API key missing');
      return null;
    }

    final trimmed = question.trim();
    if (trimmed.isEmpty) return null;

    final systemPrompt = '''
You are Chef Sprout, a warm, encouraging, and expert sous-chef helping a home cook in real time.
The cook is hands-free in the kitchen and needs immediate advice.

Context:
- Recipe: $recipeTitle
- Ingredients: ${ingredients.take(15).join(', ')}
- Current Step $stepNumber: $currentStepText

Cook's question: "$trimmed"

Instructions:
1. Answer directly and concisely in 1 to 2 spoken sentences (under 30 words maximum).
2. Be practical, friendly, and culinary-accurate.
3. Plain spoken text only. No markdown, no asterisks, no bullet points, no emojis.
''';

    for (final model in _candidateModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${AppConfig.geminiApiKey}',
      );

      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': systemPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 100,
        }
      };

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final answer = parts[0]['text'] as String?;
              if (answer != null && answer.trim().isNotEmpty) {
                // Strip any markdown asterisks, hashes, or quotes
                var clean = answer.replaceAll(RegExp(r'[\*\_\"\#]'), '').trim();
                debugPrint('GeminiSousChef ($model): $clean');
                return clean;
              }
            }
          }
        } else {
          debugPrint('GeminiSousChef ($model) HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('GeminiSousChef ($model) error: $e');
      }
    }

    return null;
  }
}
