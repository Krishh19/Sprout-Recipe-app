import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/recipe.dart';

import 'groq_service.dart';
import 'sprout_ai_service.dart';

class RecipeTranslationService {
  static final RecipeTranslationService _instance = RecipeTranslationService._internal();
  factory RecipeTranslationService() => _instance;
  RecipeTranslationService._internal();

  // In-memory cache for fast, zero-latency repeated toggles
  final Map<String, Recipe> _recipeCache = {};

  final List<String> _candidateModels = [
    'gemini-flash-lite-latest',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
  ];

  /// Detects if the given text contains Devanagari (Hindi) script characters.
  static bool isHindi(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return RegExp(r'[\u0900-\u097F]').hasMatch(text);
  }

  /// Detects if a recipe is primarily in Hindi.
  static bool isRecipeHindi(Recipe recipe) {
    if (isHindi(recipe.title)) return true;
    if (recipe.instructions.isNotEmpty && isHindi(recipe.instructions.first)) return true;
    if (recipe.description.isNotEmpty && isHindi(recipe.description)) return true;
    return false;
  }

  /// Extracts clean English title if the title is bilingual (e.g. "मशरूम पसंदा रेसिपी - Mushroom Pasanda").
  static String? extractBilingualEnglishTitle(String title) {
    // Check for " - English Title" or " : English Title"
    final sepMatch = RegExp(r'[-–—:]\s*([A-Za-z0-9\s&]+)').firstMatch(title);
    if (sepMatch != null) {
      final eng = sepMatch.group(1)?.trim();
      if (eng != null && eng.length > 2 && !isHindi(eng)) {
        return eng.replaceAll(RegExp(r'\s*\(\s*In\s+Hindi\s*\)', caseSensitive: false), '').trim();
      }
    }

    // Check for "( English Title )"
    final parenMatch = RegExp(r'\(([A-Za-z0-9\s&]+)\)').firstMatch(title);
    if (parenMatch != null) {
      final eng = parenMatch.group(1)?.trim();
      if (eng != null && !eng.toLowerCase().contains('in hindi') && !isHindi(eng)) {
        return eng.trim();
      }
    }

    return null;
  }

  /// Translates a complete Recipe between Hindi and English using Groq/Gemini with caching & fallback.
  Future<Recipe> translateRecipe(
    Recipe recipe, {
    required String targetLanguage, // 'en' or 'hi'
  }) async {
    final isSourceHindi = isRecipeHindi(recipe);
    if ((targetLanguage == 'hi' && isSourceHindi) || (targetLanguage == 'en' && !isSourceHindi)) {
      return recipe;
    }

    final cacheKey = '${recipe.id}_$targetLanguage';
    if (_recipeCache.containsKey(cacheKey)) {
      return _recipeCache[cacheKey]!;
    }

    // 1. Primary: Attempt translation via secure Supabase Edge Function 'sprout-ai'
    try {
      final map = await SproutAiService().translateRecipe(
        title: recipe.title,
        description: recipe.description,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        targetLanguage: targetLanguage,
      );
      if (map != null && map['title'] != null) {
        final title = map['title'] as String? ?? recipe.title;
        final desc = map['description'] as String? ?? recipe.description;
        final ingList = (map['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? recipe.ingredients;
        final instList = (map['instructions'] as List?)?.map((e) => e.toString()).toList() ?? recipe.instructions;

        final translated = recipe.copyWith(
          title: title,
          description: desc,
          ingredients: ingList,
          instructions: instList,
        );
        _recipeCache[cacheKey] = translated;
        return translated;
      }
    } catch (e) {
      debugPrint('RecipeTranslationService Edge function error, falling back: $e');
    }

    // 2. Attempt Groq AI translation directly if configured in environment
    if (GroqService().isAvailable) {
      try {
        final translated = await _callGroqTranslate(recipe, targetLanguage);
        if (translated != null) {
          _recipeCache[cacheKey] = translated;
          return translated;
        }
      } catch (e) {
        debugPrint('RecipeTranslationService Groq error: $e');
      }
    }

    // 2. Attempt Gemini AI translation
    if (AppConfig.geminiApiKey.isNotEmpty) {
      try {
        final translated = await _callGeminiTranslate(recipe, targetLanguage);
        if (translated != null) {
          _recipeCache[cacheKey] = translated;
          return translated;
        }
      } catch (e) {
        debugPrint('RecipeTranslationService Gemini error: $e');
      }
    }

    // Fallback translation if API key is absent or offline
    final fallback = _fallbackTranslate(recipe, targetLanguage);
    _recipeCache[cacheKey] = fallback;
    return fallback;
  }

  Future<Recipe?> _callGroqTranslate(Recipe recipe, String targetLang) async {
    final isTargetHindi = targetLang == 'hi';
    final targetLangName = isTargetHindi ? 'Hindi (Devanagari script)' : 'English';
    final sourceLangName = isTargetHindi ? 'English' : 'Hindi';

    final prompt = '''
You are an expert culinary translator for Indian and international cuisines.
Translate the following recipe from $sourceLangName to $targetLangName.
Guidelines:
1. Translate accurately, keeping cooking instructions natural, appetizing, and clear.
2. For traditional Indian ingredients and dishes, keep customary culinary names recognizable (e.g. Paneer, Tawa, Kadhai, Garam Masala).
3. Output MUST be ONLY valid JSON with this exact schema:
{
  "title": "translated title string",
  "description": "translated description string",
  "ingredients": ["translated ingredient 1", "translated ingredient 2"],
  "instructions": ["translated instruction step 1", "translated instruction step 2"]
}

Recipe Data:
Title: ${jsonEncode(recipe.title)}
Description: ${jsonEncode(recipe.description)}
Ingredients: ${jsonEncode(recipe.ingredients)}
Instructions: ${jsonEncode(recipe.instructions)}
''';

    try {
      final map = await GroqService().chatCompletionJson(
        messages: [
          {
            'role': 'system',
            'content': 'You are an expert culinary translator. Output valid JSON only matching the schema.',
          },
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 2048,
      );

      if (map != null && map['title'] != null) {
        final title = map['title'] as String? ?? recipe.title;
        final desc = map['description'] as String? ?? recipe.description;
        final ingList = (map['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? recipe.ingredients;
        final instList = (map['instructions'] as List?)?.map((e) => e.toString()).toList() ?? recipe.instructions;

        return recipe.copyWith(
          title: title,
          description: desc,
          ingredients: ingList,
          instructions: instList,
        );
      }
    } catch (e) {
      debugPrint('Groq translation error: $e');
    }
    return null;
  }

  Future<Recipe?> _callGeminiTranslate(Recipe recipe, String targetLang) async {
    final isTargetHindi = targetLang == 'hi';
    final targetLangName = isTargetHindi ? 'Hindi (Devanagari script)' : 'English';
    final sourceLangName = isTargetHindi ? 'English' : 'Hindi';

    final prompt = '''
You are an expert culinary translator for Indian and international cuisines.
Translate the following recipe from $sourceLangName to $targetLangName.
Guidelines:
1. Translate accurately, keeping cooking instructions natural, appetizing, and clear.
2. For traditional Indian ingredients and dishes, keep customary culinary names recognizable (e.g. Paneer, Tawa, Kadhai, Garam Masala).
3. Output MUST be ONLY valid raw JSON with this exact schema (no markdown, no backticks):
{
  "title": "translated title string",
  "description": "translated description string",
  "ingredients": ["translated ingredient 1", "translated ingredient 2"],
  "instructions": ["translated instruction step 1", "translated instruction step 2"]
}

Recipe Data:
Title: ${jsonEncode(recipe.title)}
Description: ${jsonEncode(recipe.description)}
Ingredients: ${jsonEncode(recipe.ingredients)}
Instructions: ${jsonEncode(recipe.instructions)}
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
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        }
      };

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              final cleanJson = text
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

              final translatedTitle = parsed['title'] as String? ?? recipe.title;
              final translatedDesc = parsed['description'] as String? ?? recipe.description;
              final translatedIngs = (parsed['ingredients'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  recipe.ingredients;
              final translatedSteps = (parsed['instructions'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  recipe.instructions;

              return recipe.copyWith(
                title: translatedTitle,
                description: translatedDesc,
                ingredients: translatedIngs,
                instructions: translatedSteps,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Gemini translate model $model attempt error: $e');
      }
    }

    return null;
  }

  Recipe _fallbackTranslate(Recipe recipe, String targetLang) {
    if (targetLang == 'en') {
      // Extract English title if available in subtitle or parentheses
      final englishTitle = extractBilingualEnglishTitle(recipe.title) ??
          (recipe.subtitle != null && !isHindi(recipe.subtitle!) ? recipe.subtitle! : null);

      return recipe.copyWith(
        title: englishTitle ?? recipe.title,
      );
    } else {
      return recipe;
    }
  }

  /// Extracts action titles for Hindi cooking instructions.
  static String getHindiActionTitle(String rawInstruction) {
    var text = rawInstruction.trim();
    if (text.isEmpty) return 'विधि चरण';

    // Remove leading numbering
    text = text.replaceFirst(RegExp(r'^(?:स्टेप\s*\d+[:\.\-]?\s*|\d+[\.\)\-]\s*)'), '').trim();
    // Remove introductory clauses like "बनाने के लिए सबसे पहले "
    text = text.replaceFirst(RegExp(r'^(?:[^,]+?बनाने\s+के\s+लिए\s+(?:सबसे\s+पहले\s+)?,?\s*)'), '').trim();

    final lower = text.toLowerCase();

    if (lower.contains('तेल गरम') || lower.contains('कढ़ाई') || lower.contains('कढ़ाई') || lower.contains('तवा गरम')) {
      if (lower.contains('तवा')) return 'तवा गरम करें';
      if (lower.contains('कढ़ाई') || lower.contains('कढ़ाई')) return 'कढ़ाई में तेल गरम करें';
      return 'तेल गरम करें';
    }

    if (lower.contains('उबालें') || lower.contains('उबाल')) {
      return 'पानी उबालें';
    }

    if (lower.contains('भूनें') || lower.contains('भूने') || lower.contains('साते')) {
      return 'मसाला भूनें';
    }

    if (lower.contains('पेस्ट') || lower.contains('पीस')) {
      return 'पेस्ट तैयार करें';
    }

    if (lower.contains('धीमी आंच') || lower.contains('पकाएं') || lower.contains('पकाए')) {
      return 'धीमी आंच पर पकाएं';
    }

    // Default: take first clause or up to 4 words
    final punctIdx = text.indexOf(RegExp(r'[\।\.\;\n]'));
    String phrase = punctIdx != -1 ? text.substring(0, punctIdx).trim() : text;
    final words = phrase.split(RegExp(r'\s+'));
    if (words.length > 4) {
      phrase = words.take(4).join(' ');
    }
    return phrase.isNotEmpty ? phrase : 'पकाने की विधि';
  }

  /// Extracts time in seconds from Hindi instruction text.
  static int extractHindiDurationSeconds(String text) {
    // 1. Check minutes in Hindi (e.g. "5 मिनट", "10 से 15 मिनट")
    final minRegExp = RegExp(r'(\d+)\s*(?:से\s*\d+\s*)?(?:मिनट|मिनट्स|मिनटों)');
    final minMatch = minRegExp.firstMatch(text);
    if (minMatch != null) {
      final mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
      if (mins > 0) return mins * 60;
    }

    // 2. Check seconds in Hindi (e.g. "30 सेकंड")
    final secRegExp = RegExp(r'(\d+)\s*(?:सेकंड|सेकेंड)');
    final secMatch = secRegExp.firstMatch(text);
    if (secMatch != null) {
      final secs = int.tryParse(secMatch.group(1) ?? '0') ?? 0;
      if (secs > 0) return secs;
    }

    // 3. Check hours in Hindi (e.g. "1 घंटा", "2 घंटे")
    final hrRegExp = RegExp(r'(\d+)\s*(?:घंटा|घंटे|घंटो)');
    final hrMatch = hrRegExp.firstMatch(text);
    if (hrMatch != null) {
      final hrs = int.tryParse(hrMatch.group(1) ?? '0') ?? 0;
      if (hrs > 0) return hrs * 3600;
    }

    // 4. Smart step timer for preheating cookware in Hindi:
    // "कढ़ाई में तेल गरम करें", "तवा गरम करें", "तेल गरम करें" -> 2 minutes (120s -> 02:00)
    final lower = text.toLowerCase();
    if (RegExp(r'(?:कढ़ाई|कढ़ाई|तवा|पैन|पतीले|कुकर|तेल|घी|ओवन)\s*(?:में)?\s*(?:तेल\s*)?गरम\s*कर(?:ें|े)|तवे\s*को\s*गरम|गरम\s*कर(?:ें|े)|धीमी\s*आंच\s*पर\s*गरम').hasMatch(lower)) {
      return 120; // 02:00
    }

    return 0;
  }
}
