import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/supabase_client.dart';

/// Ultra-fast OpenAI-compatible Groq API service for text, translations, substitutions, and nutrition.
class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Returns whether a valid direct Groq API key is configured.
  bool get isAvailable => AppConfig.groqApiKey.trim().isNotEmpty;

  /// Executes a chat completion request against the Groq API,
  /// or proxies securely via Supabase Edge Function if key is omitted on client.
  Future<String?> chatCompletion({
    required List<Map<String, String>> messages,
    String? model,
    double temperature = 0.2,
    bool jsonMode = false,
    int maxTokens = 1024,
  }) async {
    final targetModel = model ?? AppConfig.groqModel;
    final key = AppConfig.groqApiKey.trim();

    if (key.isEmpty) {
      try {
        final res = await SupabaseService.client.functions.invoke(
          'sprout-ai',
          body: {
            'task': 'chat',
            'data': {
              'messages': messages,
              'model': targetModel,
              'temperature': temperature,
              'json_mode': jsonMode,
              'max_tokens': maxTokens,
            },
          },
        ).timeout(const Duration(seconds: 20));

        final data = res.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return data['content'] as String?;
        }
      } catch (e) {
        debugPrint('GroqService edge proxy warning: $e');
      }
      return null;
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      };

      final payload = {
        'model': targetModel,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (jsonMode) 'response_format': {'type': 'json_object'},
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = decoded['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>;
          final message = firstChoice['message'] as Map<String, dynamic>?;
          return message?['content'] as String?;
        }
      } else {
        debugPrint('Groq API error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq API request exception: $e');
    }

    return null;
  }

  /// Convenience method to generate structured JSON output.
  Future<Map<String, dynamic>?> chatCompletionJson({
    required List<Map<String, String>> messages,
    String? model,
    double temperature = 0.2,
    int maxTokens = 1024,
  }) async {
    final text = await chatCompletion(
      messages: messages,
      model: model,
      temperature: temperature,
      jsonMode: true,
      maxTokens: maxTokens,
    );

    if (text == null || text.trim().isEmpty) return null;

    try {
      // Clean possible markdown code fences if model enclosed in ```json
      var cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to parse Groq JSON response: $e\nRaw: $text');
      return null;
    }
  }
}
