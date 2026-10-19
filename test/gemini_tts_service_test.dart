import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/services/gemini_tts_service.dart';

void main() {
  group('GeminiTtsService Tests', () {
    test('formatCookingText formats raw text with step prefix and pauses', () {
      final input = 'Heat olive oil in a pan. Add diced onions and cook until translucent; stir occasionally.';
      final formatted = GeminiTtsService.formatCookingText(input, 1);

      expect(formatted.startsWith('Step 1. <short pause> '), isTrue);
      expect(formatted.contains('in a pan. <short pause> Add diced onions'), isTrue);
      expect(formatted.contains('translucent; <short pause> stir occasionally.'), isTrue);
    });

    test('formatCookingText strips pre-existing Step prefixes cleanly', () {
      final input = 'Step 2: Chop fresh parsley and sprinkle on top.';
      final formatted = GeminiTtsService.formatCookingText(input, 2);

      expect(formatted.startsWith('Step 2. <short pause> Chop fresh parsley'), isTrue);
      expect(formatted.contains('Step 2:'), isFalse);
    });

    test('formatCookingText strips pre-existing numeric prefixes', () {
      final input = '3. Simmer for 10 minutes.';
      final formatted = GeminiTtsService.formatCookingText(input, 3);

      expect(formatted.startsWith('Step 3. <short pause> Simmer for 10 minutes.'), isTrue);
    });

    test('GeminiTtsService provides requested voiceDirection metadata', () {
      expect(GeminiTtsService.voiceDirection.contains('conversational voice'), isTrue);
      expect(GeminiTtsService.voiceDirection.contains('gentle, medium-to-high pitch'), isTrue);
      expect(GeminiTtsService.selectedVoice, equals('Aoede'));
    });
  });
}
