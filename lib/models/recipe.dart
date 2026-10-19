import '../design/food_image_helper.dart';
import '../design/sprout_ingredient_formatter.dart';

enum DietaryBadge { veg, egg, nonVeg }

extension RecipeTextSanitizer on String {
  String sanitizeDegreeSymbols() {
    return replaceAllMapped(
      RegExp(r'\b(\d+)\s*o\s*([CF]\b|angle\b)', caseSensitive: false),
      (match) {
        final val = match.group(1);
        final unit = match.group(2)!;
        if (unit.toLowerCase() == 'angle') {
          return '$val° angle';
        }
        return '$val°$unit';
      },
    );
  }
}

DietaryBadge resolveDietaryBadge(List<String> ingredients, {String? defaultDiet}) {
  final joined = ingredients.join(' ').toLowerCase();

  final nonVegRegex = RegExp(
    r'\b(chicken|mutton|lamb|pork|beef|fish|prawn|prawns|shrimp|crab|bacon|ham|anchovy|gelatin|meat)\b',
  );
  if (nonVegRegex.hasMatch(joined) || defaultDiet == 'non-veg' || defaultDiet == 'nonveg') {
    return DietaryBadge.nonVeg;
  }

  final eggRegex = RegExp(r'\b(egg|eggs|egg white|egg whites|egg yolk|egg yolks|mayonnaise|meringue)\b');
  if (eggRegex.hasMatch(joined) || defaultDiet == 'egg') {
    return DietaryBadge.egg;
  }

  return DietaryBadge.veg;
}

class Recipe {
  final String id;
  final String title;
  final String? slug;
  final String description;
  final List<String> ingredients;
  final List<String> cleanedIngredients;
  final List<String> instructions;
  final int totalTimeMins;
  final String cuisine;
  final String? sourceUrl;
  final String? imageUrl;
  final int servings;
  final double? rating;
  final int reviewCount;
  final String diet;
  final bool isSaved;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final double matchPercentage;

  const Recipe({
    required this.id,
    required this.title,
    this.slug,
    required this.description,
    required this.ingredients,
    required this.cleanedIngredients,
    required this.instructions,
    required this.totalTimeMins,
    required this.cuisine,
    this.sourceUrl,
    this.imageUrl,
    this.servings = 1,
    this.rating,
    this.reviewCount = 0,
    this.diet = 'veg',
    this.isSaved = false,
    this.matchedIngredients = const [],
    this.missingIngredients = const [],
    this.matchPercentage = 0.0,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    List<String>? ingredients,
    List<String>? cleanedIngredients,
    List<String>? instructions,
    int? totalTimeMins,
    String? cuisine,
    String? sourceUrl,
    String? imageUrl,
    int? servings,
    double? rating,
    int? reviewCount,
    String? diet,
    bool? isSaved,
    List<String>? matchedIngredients,
    List<String>? missingIngredients,
    double? matchPercentage,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      cleanedIngredients: cleanedIngredients ?? this.cleanedIngredients,
      instructions: instructions ?? this.instructions,
      totalTimeMins: totalTimeMins ?? this.totalTimeMins,
      cuisine: cuisine ?? this.cuisine,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      servings: servings ?? this.servings,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      diet: diet ?? this.diet,
      isSaved: isSaved ?? this.isSaved,
      matchedIngredients: matchedIngredients ?? this.matchedIngredients,
      missingIngredients: missingIngredients ?? this.missingIngredients,
      matchPercentage: matchPercentage ?? this.matchPercentage,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json, {bool isSaved = false}) {
    List<String> parseList(dynamic val, {bool isInstructions = false}) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString().trim()).toList();
      if (val is String) {
        if (val.startsWith('[') && val.endsWith(']')) {
          // json array representation
          return val
              .substring(1, val.length - 1)
              .split(',')
              .map((s) => s.replaceAll('"', '').replaceAll("'", '').trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (isInstructions && val.contains('\n')) {
          return val
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final rawIngredients = parseList(json['ingredients'] ?? json['TranslatedIngredients']);
    List<String> normalizedIngredients = [];
    try {
      normalizedIngredients = rawIngredients
          .map((ing) {
            try {
              return SproutIngredientFormatter.normalize(ing);
            } catch (_) {
              return ing;
            }
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      normalizedIngredients = rawIngredients;
    }

    final instructionsList = parseList(json['instructions'] ?? json['TranslatedInstructions'], isInstructions: true);

    // Validate cooking time: Never allow 0 min or negative minutes!
    int validatedTime = (json['total_time_mins'] ?? json['TotalTimeInMins'] ?? 0) is int
        ? (json['total_time_mins'] ?? json['TotalTimeInMins'] ?? 0)
        : int.tryParse(json['total_time_mins']?.toString() ?? '') ?? 0;

    if (validatedTime <= 0) {
      final prep = int.tryParse(json['PrepTimeInMins']?.toString() ?? '') ?? 0;
      final cook = int.tryParse(json['CookTimeInMins']?.toString() ?? '') ?? 0;
      if (prep + cook > 0) {
        validatedTime = prep + cook;
      } else {
        validatedTime = (instructionsList.length * 5).clamp(15, 45);
      }
    }

    final effectiveIngredients = normalizedIngredients.isNotEmpty ? normalizedIngredients : rawIngredients;
    final resolvedDietaryBadge = resolveDietaryBadge(
      effectiveIngredients,
      defaultDiet: json['diet']?.toString(),
    );
    final String resolvedDietStr;
    switch (resolvedDietaryBadge) {
      case DietaryBadge.egg:
        resolvedDietStr = 'egg';
        break;
      case DietaryBadge.nonVeg:
        resolvedDietStr = 'non-veg';
        break;
      case DietaryBadge.veg:
        resolvedDietStr = 'veg';
        break;
    }

    final sanitizedInstructions = instructionsList.map((i) => i.sanitizeDegreeSymbols()).toList();
    final sanitizedDescription = (json['description'] ?? 'A comforting and flavorful meal cooked with care.')
        .toString()
        .sanitizeDegreeSymbols();

    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['TranslatedRecipeName'] ?? 'Delicious Dish',
      slug: json['slug'],
      description: sanitizedDescription,
      ingredients: effectiveIngredients,
      cleanedIngredients: parseList(json['cleaned_ingredients'] ?? json['Cleaned-Ingredients']),
      instructions: sanitizedInstructions,
      totalTimeMins: validatedTime,
      cuisine: json['cuisine'] ?? json['Cuisine'] ?? 'Indian',
      sourceUrl: json['source_url'] ?? json['URL'],
      imageUrl: FoodImageHelper.getValidImageUrl(
        originalUrl: json['image_url'] ?? json['image-url'],
        title: json['title'] ?? json['TranslatedRecipeName'] ?? 'Delicious Dish',
        cuisine: json['cuisine'] ?? json['Cuisine'] ?? 'Indian',
      ),
      servings: (json['servings'] as num?)?.toInt() == 4
          ? 1
          : ((json['servings'] as num?)?.toInt() ?? 1),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      diet: resolvedDietStr,
      isSaved: isSaved,
      matchedIngredients: parseList(json['matched_ingredients']),
      missingIngredients: parseList(json['missing_ingredients']),
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'ingredients': ingredients,
      'cleaned_ingredients': cleanedIngredients,
      'instructions': instructions,
      'total_time_mins': totalTimeMins,
      'cuisine': cuisine,
      'source_url': sourceUrl,
      'image_url': imageUrl,
      'servings': servings,
      'rating': rating,
      'review_count': reviewCount,
      'diet': diet,
    };
  }

  /// Resolved dietary badge (veg, egg, or non-veg)
  DietaryBadge get dietaryBadge => resolveDietaryBadge(ingredients, defaultDiet: diet);

  /// Clean, human-friendly short display title (2-7 words)
  String get displayTitle => RecipeTitleCleaner.clean(title).displayTitle;

  /// Optional editorial subtitle (e.g. "Sweet & spicy drumsticks cooked in coconut water")
  String? get subtitle => RecipeTitleCleaner.clean(title).subtitle;
}

class RecipeTitleParts {
  final String displayTitle;
  final String? subtitle;

  const RecipeTitleParts({
    required this.displayTitle,
    this.subtitle,
  });
}

class RecipeTitleCleaner {
  /// Cleans verbose/AI-generated recipe titles into a scannable 2-7 word display title
  /// and an optional descriptive subtitle.
  /// Example: "Parsi Style Sekta Ni Sing Recipe-Sweet & Spicy Drumsticks Cooked In Coconut Water/Toddy Recipe"
  /// -> displayTitle: "Parsi-Style Sekta Ni Sing"
  /// -> subtitle: "Sweet & spicy drumsticks cooked in coconut water"
  static RecipeTitleParts clean(String raw) {
    if (raw.trim().isEmpty) {
      return const RecipeTitleParts(displayTitle: 'Delicious Dish');
    }

    String text = raw.trim();

    // 1. Convert "Recipe-" or "Recipe - " into a standard separator
    text = text.replaceAll(RegExp(r'\bRecipe\s*[-–—:]\s*', caseSensitive: false), ' - ');

    // 2. Remove trailing "Recipe" or "- Recipe"
    text = text.replaceAll(RegExp(r'[\s\-–—]*\bRecipe\b[\s\.]*$', caseSensitive: false), '').trim();

    String mainPart = text;
    String? subPart;

    if (text.contains(' - ')) {
      final parts = text.split(' - ');
      mainPart = parts[0].trim();
      subPart = parts.sublist(1).join(' · ').trim();
    } else if (text.contains(': ')) {
      final parts = text.split(': ');
      mainPart = parts[0].trim();
      subPart = parts.sublist(1).join(' · ').trim();
    } else if (text.contains(' | ')) {
      final parts = text.split(' | ');
      mainPart = parts[0].trim();
      subPart = parts.sublist(1).join(' · ').trim();
    } else if (text.contains('-') && !text.contains('-Style')) {
      final idx = text.indexOf('-');
      if (idx > 3 && idx < text.length - 3) {
        mainPart = text.substring(0, idx).trim();
        subPart = text.substring(idx + 1).trim();
      }
    }

    // 3. Normalize "Style" -> "Style" with hyphen (e.g. "Parsi Style" -> "Parsi-Style")
    mainPart = mainPart.replaceAllMapped(
      RegExp(r'\b([A-Za-z]+)\s+Style\b', caseSensitive: false),
      (m) => '${m[1]}-Style',
    );
    mainPart = mainPart.replaceAll(RegExp(r'\bRecipe\b', caseSensitive: false), '').trim();
    mainPart = mainPart.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    if (subPart != null) {
      subPart = subPart.replaceAll(RegExp(r'\bRecipe\b', caseSensitive: false), '').trim();
      subPart = subPart.replaceAll(RegExp(r'[\/\\]+'), ' · ').trim();
      subPart = subPart.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      if (subPart.isEmpty) subPart = null;
    }

    // 4. If mainPart is still excessively long (> 7 words) and no subpart was found,
    // look for natural phrase splits like "Cooked In", "With", "In", "Served With"
    final words = mainPart.split(RegExp(r'\s+'));
    if (words.length > 7 && subPart == null) {
      final splitMatch = RegExp(r'\b(cooked in|with|in|served with)\b', caseSensitive: false).firstMatch(mainPart);
      if (splitMatch != null && splitMatch.start > 5) {
        subPart = mainPart.substring(splitMatch.start).trim();
        mainPart = mainPart.substring(0, splitMatch.start).trim();
      } else {
        mainPart = words.take(6).join(' ');
        subPart = words.skip(6).join(' ');
      }
    }

    // Capitalize first letter of subtitle
    if (subPart != null && subPart.isNotEmpty) {
      subPart = subPart[0].toUpperCase() + subPart.substring(1);
    }

    return RecipeTitleParts(
      displayTitle: mainPart.isNotEmpty ? mainPart : raw.trim(),
      subtitle: subPart,
    );
  }
}

