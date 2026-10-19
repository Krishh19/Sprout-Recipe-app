# Sprout (Krishh19/Sprout-Recipe-app) — Flutter Technical Audit & Fix Guide

This technical audit covers the **logic/data bugs**, **Gemini 3.8 Flash-Lite TTS fallback bug**, **UI/layout flaws**, and **modern Flutter animation/layout upgrades** identified in the current build of Sprout.

---

## 1. Critical Logic, Search, Audio & Data Bugs

### 1.1 Substring Ingredient Matching False Positives (`00:18 – 00:31`)
* **Observed Bug:** The AI scanner detects `Butter` and `Egg` in the refrigerator (`00:18`). On the **Matching Recipes** screen, **Peanut Butter Cookies** ranks first at a **66% Match** (`00:21`), and the detail screen claims the user already has `1 cup Peanut Butter` in their pantry (`00:31`).
* **Root Cause:** The ingredient matcher performs a loose substring check (`recipeIngredient.toLowerCase().contains(scannedItem.toLowerCase())`), causing `"butter"` to match `"peanut butter"`.
* **Flutter / Dart Fix:** Normalize ingredient strings into exact canonical tokens and block compound modifiers when matching single-word ingredients:

```dart
class IngredientMatcher {
  static const Map<String, Set<String>> _compoundExclusions = {
    'butter': {'peanut butter', 'almond butter', 'cashew butter', 'cocoa butter', 'buttermilk', 'butterscotch'},
    'milk': {'coconut milk', 'almond milk', 'oat milk', 'soy milk', 'buttermilk', 'condensed milk'},
    'apple': {'pineapple', 'custard apple', 'wood apple'},
    'pepper': {'bell pepper', 'black pepper', 'white pepper', 'cayenne pepper', 'chili pepper'},
    'oil': {'sesame oil', 'chili oil', 'truffle oil', 'coconut oil', 'mustard oil'},
  };

  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .replaceAll(RegExp(r'\b(fresh|organic|raw|chopped|diced|sliced|large|small|cup|cups|tbsp|tsp)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool isMatch({required String userItem, required String recipeIngredient}) {
    final normUser = normalize(userItem);
    final normRecipe = normalize(recipeIngredient);

    if (normUser.isEmpty || normRecipe.isEmpty) return false;
    if (normUser == normRecipe) return true;

    final exclusions = _compoundExclusions[normUser];
    if (exclusions != null && exclusions.any((compound) => normRecipe.contains(compound))) {
      return false;
    }

    final userWords = normUser.split(' ');
    final recipeWords = normRecipe.split(' ');

    if (userWords.length == 1 && recipeWords.length > 1) {
      return false; 
    }

    return RegExp(r'\b' + RegExp.escape(normUser) + r's?\b').hasMatch(normRecipe);
  }
}
```

---

### 1.2 Desynchronized "Zero Missing (100% Match)" Filter Chip (`00:21 – 00:24`)

* **Observed Bug:** When entering `Matching Recipes (50)`, the `Zero Missing (100% Match)` filter chip displays as active with a green checkmark box, yet the list displays **66% Match**, **60% Match**, and **57% Match** recipes that all have missing items.
* **Root Cause:** The `FilterChip` has a hardcoded leading checkmark icon regardless of its `selected` state, or `onlyZeroMissing` defaults to `true` in the UI widget while the recipe list query remains unfiltered on initial load.
* **Flutter / Dart Fix:** Bind the `FilterChip` directly to your filtered list state:

```dart
FilterChip(
  label: const Text('Zero Missing (100% Match)'),
  selected: state.onlyZeroMissing,
  showCheckmark: true,
  selectedColor: const Color(0xFFE6F4EA),
  checkmarkColor: const Color(0xFF1E6B43),
  onSelected: (bool value) {
    ref.read(recipeMatchProvider.notifier).toggleZeroMissing(value);
  },
)
```

---

### 1.3 Incorrect Vegetarian Badge on Egg Recipes (`00:25 – 00:31`)

* **Observed Bug:** **Peanut Butter Cookies** displays a green vegetarian dot badge (`00:25`), even though its ingredient list explicitly includes `1 Egg` (`00:31`).
* **Root Cause:** Trusting an unvalidated `isVeg` flag from the dataset without inspecting the ingredient list for eggs.
* **Flutter / Dart Fix:** Derive dietary classification dynamically in your model parser:

```dart
enum DietaryBadge { veg, egg, nonVeg }

DietaryBadge resolveDietaryBadge(List<String> ingredients, {bool defaultIsVeg = true}) {
  final joined = ingredients.join(' ').toLowerCase();

  final nonVegRegex = RegExp(
    r'\b(chicken|mutton|lamb|pork|beef|fish|prawn|prawns|shrimp|crab|bacon|ham|anchovy|gelatin)\b',
  );
  if (nonVegRegex.hasMatch(joined) || !defaultIsVeg) {
    return DietaryBadge.nonVeg;
  }

  final eggRegex = RegExp(r'\b(egg|eggs|egg white|egg yolk|mayonnaise|meringue)\b');
  if (eggRegex.hasMatch(joined)) {
    return DietaryBadge.egg;
  }

  return DietaryBadge.veg;
}
```

---

### 1.4 Context-Blind AI Pantry Substitutions (`00:33 – 00:34`)

* **Observed Bug:** Under `You Need (1): 1/2 cup Sugar` in **Peanut Butter Cookies**, the **Pantry Substitutions** card advises: *"No sugar -> Pantry staple alternative or omit: Adjust salt and warming spices to taste; dish will still turn out delicious!"* (`00:34`).
* **Root Cause:** A generic savory fallback string is returned when a specific lookup fails, ignoring that the recipe is a `Dessert`.
* **Flutter / Dart Fix:** Implement category-aware fallback logic:

```dart
String getFallbackSubstitution(String missingIngredient, String category) {
  final norm = missingIngredient.toLowerCase();
  final isSweet = category.toLowerCase().contains('dessert') ||
      category.toLowerCase().contains('baking') ||
      category.toLowerCase().contains('sweet');

  if (norm.contains('sugar')) {
    return isSweet
        ? 'Swap with equal parts jaggery powder, brown sugar, or 1/3 cup honey/maple syrup.'
        : 'Add a pinch of jaggery, honey, or caramelized onions to balance acidity.';
  }
  return isSweet
      ? 'Check baking substitutions for $missingIngredient to maintain dough texture.'
      : 'Omit or adjust salt, herbs, and aromatics to taste.';
}
```

---

### 1.5 Corrupted Degree Symbol Encoding (`00:36 & 00:42`)

* **Observed Bug:** Recipe instructions display `350oF (180oC)` (`00:36`, `00:42`) and `90o angle` (`00:37`) using a lowercase `'o'` instead of the degree symbol `°`.
* **Flutter / Dart Fix:** Sanitize instruction strings during JSON parsing:

```dart
extension RecipeTextSanitizer on String {
  String sanitizeDegreeSymbols() {
    return replaceAllMapped(
      RegExp(r'\b(\d+)\s*o\s*([CF]\b|angle\b)', caseSensitive: false),
      (match) => '${match.group(1)}°${match.group(2)}',
    );
  }
}
```

---

### 1.6 Unfiltered Multi-Language Recipe Cards (`00:05 – 00:06`)

* **Observed Bug:** On the Home screen under **Trending Recipes**, English cards sit directly beside Hindi Devanagari cards while app language is set to `EN`.
* **Flutter / Dart Fix:** Filter cards by script/locale:

```dart
final devanagariRegex = RegExp(r'[\u0900-\u097F]');

List<Recipe> filterByLocale(List<Recipe> recipes, String languageCode) {
  if (languageCode == 'en') {
    return recipes.where((r) => !devanagariRegex.hasMatch(r.title)).toList();
  }
  return recipes;
}
```

---

### 1.7 Alphabetical Sorting & Ignored Kitchen Staples (`00:18` & `01:11 – 01:16`)

* **Observed Bugs:**
1. `Water` is detected in the fridge scan (`00:18`) and counted as an active ingredient.
2. The **Explore** tab (`01:11`) lists recipes strictly from A to Z rather than using contextual sorting.

* **Flutter / Dart Fix:** Filter out assumed staples (`water`, `salt`, `oil`) from AI vision sheets, and replace alphabetical sorting with a weighted score combining time-of-day and user profile preferences.

---

### 1.8 `gemini-3.8-flash-lite-tts` Silently Failing to Robotic `flutter_tts` (`00:46 – 00:53`)

* **Observed Bug:** Tapping the speaker button (`00:46`) shows the speaking banner (`00:47`), pauses for ~1.5s, and then plays the robotic system TTS (`flutter_tts`) instead of the Gemini voice.
* **Root Cause:** Using the legacy `google_generative_ai` Dart package (which lacks support for `responseModalities: ["AUDIO"]`), omitting Gemini 3.8 speech metadata requirements, or passing raw PCM bytes without a 44-byte `RIFF` WAV header to `audioplayers`.
* **Flutter / Dart Fix:** Use direct REST calls to `v1beta` with explicit WAV wrapping:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class ChefSproutTtsService {
  ChefSproutTtsService({required this.apiKey});
  final String apiKey;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();

  static const String _model = 'gemini-3.8-flash-lite-tts';
  static const String _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<void> speakStep(String instructionText) async {
    await stop();
    final sanitizedText = instructionText.trim();
    if (sanitizedText.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'role': 'user',
            'parts': [{
              'text': sanitizedText,
              'speech_metadata': {'style': 'warm, clear, friendly culinary instructor pacing'},
            }],
          }],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': 'Aoede'},
              },
            },
          },
        }),
      );

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      final parts = data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
      final inlineData = parts?.firstWhere((p) => p['inlineData'] != null, orElse: () => null)?['inlineData'];

      if (inlineData == null || inlineData['data'] == null) throw Exception('Missing audio bytes');

      final Uint8List rawBytes = base64Decode(inlineData['data'] as String);
      final Uint8List wavBytes = _ensureWavHeader(rawBytes, sampleRate: 24000);

      await _audioPlayer.play(BytesSource(wavBytes, mimeType: 'audio/wav'));
    } catch (e) {
      debugPrint('Gemini TTS failed, falling back to FlutterTts: $e');
      await _fallbackTts.setLanguage('en-US');
      await _fallbackTts.speak(sanitizedText);
    }
  }

  Uint8List _ensureWavHeader(Uint8List bytes, {int sampleRate = 24000}) {
    if (bytes.length >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return bytes;
    }
    final int byteRate = sampleRate * 2;
    final int dataLength = bytes.length;
    final ByteData header = ByteData(44);

    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, 36 + dataLength, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataLength, Endian.little);

    return BytesBuilder(copy: false)..add(header.buffer.asUint8List())...add(bytes).toBytes();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    await _fallbackTts.stop();
  }
}
```

---

## 2. UI, Layout & UX Flow Fixes

### 2.1 Header & Tab Text Truncation Across Screens

* **Observed Bugs:** Search hints, weekly meal subtitles, scan sheet titles, the `"Your Ingredients"` header (`00:19`), and the `"Ingredients"` tab (`00:25`) clip or truncate text.
* **Flutter Layout Fixes:**
* Use modern `Row`/`Column` `spacing` parameters and wrap truncated labels in `Flexible` or `Expanded`.
* Set `labelPadding: const EdgeInsets.symmetric(horizontal: 8)` on `TabBar` to prevent tab label clipping.

### 2.2 Premature `[Tap to expand]` in Cooking Mode (`01:00`)

* **Observed Bug:** Short instructions collapse behind a `[Tap to expand]` button while 60% of the screen remains blank.
* **Flutter Layout Fix:** Remove hardcoded `maxLines: 2` collapse behavior on active cooking steps and let content flow naturally inside a `SingleChildScrollView`.

### 2.3 Voice Assistant Banner Overlapping Step Title (`00:47 – 01:01`)

* **Observed Bug:** Tapping speaker/mic triggers an overlay banner that blocks step titles.
* **Flutter Layout Fix:** Place the status banner directly inside the layout wrapper using **`AnimatedSize`** so it pushes content smoothly instead of covering it.

### 2.4 Persistent Snackbar Obstructing Scroll (`00:19`)

* **Observed Bug:** Ingredient addition toasts stay pinned for 5 seconds over scrollable content.
* **Flutter Layout Fix:** Shorten snackbar display duration and dismiss on scroll notifications.

---

## 3. Modern Flutter Animation & Layout Tech Upgrades (2026 Stack)

* **3.1 Skeletonizer + CachedNetworkImage:** Replace raw spinner boxes on recipe thumbnails with `Skeletonizer` and `cached_network_image` with `memCacheWidth: 300` for smooth scrolling.
* **3.2 Material Container Transform:** Use `OpenContainer` from the official `animations` package for smooth list-to-detail transitions.
* **3.3 Unified Scroll Physics:** Use `PinnedHeaderSliver` and `SliverMainAxisGroup` to pin filter bars and tab headers to the viewport cleanly.
* **3.4 Declarative Staggered Entrances:** Use `flutter_animate` for staggered chip entrances on modal sheets.

---

## 4. Recommended `pubspec.yaml` Additions

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  audioplayers: ^6.1.0
  flutter_tts: ^4.2.0
  animations: ^2.0.11
  flutter_animate: ^4.5.2
  skeletonizer: ^1.4.3
  cached_network_image: ^3.4.1
  wakelock_plus: ^1.2.10
```
