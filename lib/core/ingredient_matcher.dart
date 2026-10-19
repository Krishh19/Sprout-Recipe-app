/// Robust ingredient matching engine with canonical tokenization and compound exclusions.
/// Prevents false positives such as matching "butter" with "peanut butter" or "apple" with "pineapple".
class IngredientMatcher {
  IngredientMatcher._();

  static const Map<String, Set<String>> _compoundExclusions = {
    'butter': {
      'peanut butter',
      'almond butter',
      'cashew butter',
      'cocoa butter',
      'cacao butter',
      'buttermilk',
      'butterscotch',
      'apple butter',
      'cookie butter',
    },
    'milk': {
      'coconut milk',
      'almond milk',
      'oat milk',
      'soy milk',
      'buttermilk',
      'condensed milk',
      'evaporated milk',
      'milk powder',
    },
    'cream': {
      'ice cream',
      'cream cheese',
      'sour cream',
      'tartar cream',
      'cream of tartar',
    },
    'apple': {
      'pineapple',
      'custard apple',
      'wood apple',
      'apple cider vinegar',
    },
    'pepper': {
      'bell pepper',
      'black pepper',
      'white pepper',
      'cayenne pepper',
      'chili pepper',
      'peppercorn',
    },
    'oil': {
      'sesame oil',
      'chili oil',
      'truffle oil',
      'coconut oil',
      'mustard oil',
      'castor oil',
    },
    'corn': {
      'popcorn',
      'peppercorn',
      'cornstarch',
      'cornflour',
      'corn syrup',
    },
    'bean': {
      'coffee bean',
      'vanilla bean',
      'jelly bean',
    },
    'nut': {
      'peanut',
      'walnut',
      'coconut',
      'hazelnut',
      'chestnut',
      'doughnut',
      'butternut',
    },
    'egg': {
      'eggplant',
    },
  };

  /// Common adjectives, descriptors, and quantity units to strip for clean comparison
  static final RegExp _descriptorRegex = RegExp(
    r'\b(fresh|organic|raw|chopped|diced|sliced|minced|grated|crushed|shredded|pureed|'
    r'powdered|toasted|roasted|boiled|cooked|large|small|medium|cup|cups|tbsp|tsp|'
    r'tablespoon|tablespoons|teaspoon|teaspoons|gram|grams|g|kg|ml|oz|pound|pounds|'
    r'pinch|pinches|dash|piece|pieces|slice|slices|bunch|handful|can|cans)\b',
    caseSensitive: false,
  );

  /// Normalizes ingredient strings into clean lowercase canonical tokens
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(_descriptorRegex, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Determines whether a scanned/user item matches a recipe ingredient
  static bool isMatch({
    required String userItem,
    required String recipeIngredient,
  }) {
    final normUser = normalize(userItem);
    final normRecipe = normalize(recipeIngredient);

    if (normUser.isEmpty || normRecipe.isEmpty) return false;

    // Direct canonical equality
    if (normUser == normRecipe) return true;

    // Check compound exclusions for userItem
    final exclusions = _compoundExclusions[normUser];
    if (exclusions != null) {
      final rawRecipeLower = recipeIngredient.toLowerCase();
      if (exclusions.any((comp) => normRecipe.contains(comp) || rawRecipeLower.contains(comp))) {
        return false;
      }
    }

    // Also check reverse compound exclusions if userItem itself is compound
    for (final entry in _compoundExclusions.entries) {
      if (normRecipe == entry.key) {
        if (entry.value.any((comp) => normUser.contains(comp))) {
          return false;
        }
      }
    }

    // Word boundary match: matches e.g. "butter" in "unsalted butter" or "eggs" in "2 large eggs"
    final escaped = RegExp.escape(normUser);
    final pattern = RegExp(r'\b' + escaped + r's?\b', caseSensitive: false);
    if (pattern.hasMatch(normRecipe)) {
      return true;
    }

    // Plural/singular normalization
    if (normUser.endsWith('s') && normUser.length > 3) {
      final singular = normUser.substring(0, normUser.length - 1);
      if (RegExp(r'\b' + RegExp.escape(singular) + r'\b', caseSensitive: false).hasMatch(normRecipe)) {
        return true;
      }
    }

    return false;
  }
}
