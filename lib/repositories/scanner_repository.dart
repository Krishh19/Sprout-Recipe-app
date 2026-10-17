import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config.dart';
import '../services/sprout_ai_service.dart';

class ScannerRepository {
  // Preset ingredient bundles retained for manual preset selection or testing
  static final Map<String, List<String>> presetBundles = {
    'Fresh Produce': ['tomato', 'onion', 'garlic', 'spinach', 'paneer'],
    'Quick Pantry': ['potatoes', 'cumin seeds', 'coriander powder', 'turmeric powder'],
    'Comfort Dal': ['toor dal', 'spinach', 'garlic', 'green chilli', 'ghee'],
    'Spicy Stir Fry': ['karela', 'onion', 'besan', 'amchur', 'cumin seeds'],
  };

  static const List<String> _candidateModels = [
    'gemini-flash-lite-latest',
    'gemini-3.8-flash',
  ];

  static const String _visionPrompt = '''
You are an expert culinary AI for the Sprout cooking app.
Analyze this photo carefully. The photo may show:
1. A prepared dish or cooked recipe (e.g., salad, bowl, soup, curry, stir-fry, pasta, sandwich):
   Identify all visible culinary ingredients and components that make up the dish.
2. Fridge interior or pantry shelves:
   Identify all visible groceries, vegetables, condiments, dairy, staples, and food items.
3. Raw groceries or kitchen counter items:
   Identify each individual fruit, vegetable, herb, protein, or pantry item.
4. A recipe card, menu, or cookbook page:
   Extract all individual culinary ingredients listed in the recipe text.

Instructions:
- Return ONLY a valid JSON array of lowercase singular ingredient names (e.g. ["egg", "avocado", "tomato", "chicken", "lettuce"]).
- Break compound dishes down into their component ingredients (e.g., if you see a chicken salad, list "chicken", "lettuce", "egg", "avocado", "tomato", "bacon", etc.).
- Exclude non-food objects like bowls, plates, forks, napkins, or packaging.
- Output ONLY the valid JSON array without any markdown formatting, backticks, or conversational text.
''';

  /// Analyzes an image of food, groceries, pantry, fridge, or recipe using Gemini multimodal vision.
  /// Dynamically detects MIME type and iterates over candidate models with fast fallback.
  Future<List<String>> analyzeImageWithGemini(Uint8List imageBytes) async {
    final mimeType = _detectMimeType(imageBytes);

    // 1. Primary: Use secure Supabase Edge Function 'sprout-ai' (Gemini vision server-side)
    try {
      final edgeIngredients = await SproutAiService().analyzeImage(
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      if (edgeIngredients != null && edgeIngredients.isNotEmpty) {
        return edgeIngredients;
      }
    } catch (e) {
      debugPrint('ScannerRepository Edge vision error, falling back: $e');
    }

    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      debugPrint('ScannerRepository: Gemini API key is empty.');
      return [];
    }

    final base64Image = base64Encode(imageBytes);

    // 2. Direct HTTP request with candidate models (if local developer key provided)
    for (final model in _candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final payload = {
          'contents': [
            {
              'parts': [
                {'text': _visionPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.1,
          }
        };

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                final ingredients = _parseIngredientsJson(text);
                if (ingredients.isNotEmpty) {
                  debugPrint(
                    'ScannerRepository ($model) identified ${ingredients.length} ingredients: $ingredients',
                  );
                  return ingredients;
                }
              }
            }
          }
        } else {
          debugPrint(
            'ScannerRepository ($model) HTTP ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('ScannerRepository ($model) attempt error: $e');
      }
    }

    // 2. Fallback to GenerativeModel SDK if direct HTTP attempts failed
    try {
      final sdkModel = GenerativeModel(
        model: 'gemini-flash-lite-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1,
        ),
      );

      final content = [
        Content.multi([
          TextPart(_visionPrompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await sdkModel.generateContent(content);
      final text = response.text?.trim() ?? '';
      if (text.isNotEmpty) {
        final ingredients = _parseIngredientsJson(text);
        if (ingredients.isNotEmpty) {
          debugPrint(
            'ScannerRepository (SDK fallback) identified ${ingredients.length} ingredients: $ingredients',
          );
          return ingredients;
        }
      }
    } catch (e) {
      debugPrint('ScannerRepository SDK fallback error: $e');
    }

    // Return empty list if no ingredients could be identified (never return fake hardcoded data)
    return [];
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  List<String> _parseIngredientsJson(String text) {
    try {
      final startIndex = text.indexOf('[');
      final endIndex = text.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonSub = text.substring(startIndex, endIndex + 1);
        final List<dynamic> decoded = jsonDecode(jsonSub);
        return decoded
            .map((e) => e.toString().toLowerCase().trim())
            .where((e) => e.isNotEmpty && !e.startsWith('[') && !e.endsWith(']'))
            .toSet()
            .toList();
      }
    } catch (e) {
      debugPrint('ScannerRepository parse error: $e');
    }
    return [];
  }
}
