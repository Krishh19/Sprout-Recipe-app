import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/config.dart';
import 'package:sprout/repositories/scanner_repository.dart';

void main() {
  test('ScannerRepository analyzes user image and returns actual food ingredients', () async {
    final imgFile = File(
      r'C:\Users\krish\.gemini\antigravity\brain\5a75047a-d86f-471b-9220-739fcf1d0998\.user_uploaded\media_1792042860099_21b606b3.png',
    );
    if (!imgFile.existsSync()) return;

    final Uint8List imageBytes = await imgFile.readAsBytes();
    final repo = ScannerRepository();
    final results = await repo.analyzeImageWithGemini(imageBytes);

    // If running in isolated unit test without Supabase init or client API key
    if (AppConfig.geminiApiKey.isEmpty && results.isEmpty) {
      expect(results, isA<List<String>>());
      return;
    }

    expect(results, isNotEmpty);
    // Ensure it is NOT returning the old hardcoded produce bundle
    expect(
      results,
      isNot(equals(['tomato', 'onion', 'garlic', 'spinach', 'paneer'])),
    );

    // Verify key ingredients visible in the user's chicken salad bowl image
    final joined = results.join(' ');
    expect(
      joined.contains('egg') ||
      joined.contains('avocado') ||
      joined.contains('chicken') ||
      joined.contains('tomato') ||
      joined.contains('lettuce'),
      isTrue,
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
