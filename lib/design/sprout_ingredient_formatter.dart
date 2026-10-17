class SproutIngredientFormatter {
  /// Cleans raw dataset and CSV ingredient strings into elegant, human-readable culinary text.
  /// Example: "2-1 / 2 cups rice - cooked" -> "2½ cups cooked rice"
  /// Example: "1-1 / 2 tablespoon oil - 1/2 teaspoon asafoetida" -> "1½ tbsp oil, ½ tsp asafoetida"
  static String normalize(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw.trim();

    // 1. Remove surrounding brackets or quotes
    text = text.replaceAll(RegExp(r'''^[\["'\(]+|[\]"'\)]+$'''), '').trim();

    // 2. Normalize awkward fractions
    text = text
        .replaceAll(RegExp(r'\b1-1\s*/\s*2\b|\b1\s+1\s*/\s*2\b|\b1-1/2\b'), '1½')
        .replaceAll(RegExp(r'\b2-1\s*/\s*2\b|\b2\s+1\s*/\s*2\b|\b2-1/2\b'), '2½')
        .replaceAll(RegExp(r'\b3-1\s*/\s*2\b|\b3\s+1\s*/\s*2\b|\b3-1/2\b'), '3½')
        .replaceAll(RegExp(r'\b1\s*/\s*2\b|\b1/2\b'), '½')
        .replaceAll(RegExp(r'\b1\s*/\s*4\b|\b1/4\b'), '¼')
        .replaceAll(RegExp(r'\b3\s*/\s*4\b|\b3/4\b'), '¾')
        .replaceAll(RegExp(r'\b1\s*/\s*3\b|\b1/3\b'), '⅓')
        .replaceAll(RegExp(r'\b2\s*/\s*3\b|\b2/3\b'), '⅔')
        .replaceAll(RegExp(r'\b1\s*/\s*8\b|\b1/8\b'), '⅛');

    // 3. Clean common abbreviation spacing
    text = text
        .replaceAll(RegExp(r'\btablespoon\b|\btablespoons\b', caseSensitive: false), 'tbsp')
        .replaceAll(RegExp(r'\bteaspoon\b|\bteaspoons\b', caseSensitive: false), 'tsp');

    // 4. Clean trailing notes like " - cooked", " - washed", " - finely chopped"
    text = text
        .replaceAll(RegExp(r'\s*-\s*finely\s+chopped\b', caseSensitive: false), ' (chopped)')
        .replaceAll(RegExp(r'\s*-\s*cooked\b', caseSensitive: false), ' (cooked)')
        .replaceAll(RegExp(r'\s*-\s*chopped\b', caseSensitive: false), ' (chopped)')
        .replaceAll(RegExp(r'\s*-\s*washed\b', caseSensitive: false), ' (washed)')
        .replaceAll(RegExp(r'(?<!\(|\w)chopped(?!(\)|\w))', caseSensitive: false), '(chopped)')
        .replaceAll(RegExp(r'(?<!\(|\w)washed(?!(\)|\w))', caseSensitive: false), '(washed)')
        .replaceAll(RegExp(r'\s*-\s*slit\b', caseSensitive: false), ' (slit)')
        .replaceAll(RegExp(r'\s*-\s*diced\b', caseSensitive: false), ' (diced)')
        .replaceAll(RegExp(r'\s*-\s*smashed\b', caseSensitive: false), ' (smashed)')
        .replaceAll(RegExp(r'\s*-\s*to taste\b', caseSensitive: false), ' to taste');

    // 5. Replace stray dashes that separate combined items
    text = text.replaceAll(RegExp(r'\s+-\s+'), ', ');

    // 6. Capitalize first letter cleanly
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    // 7. Collapse excess whitespace
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return text;
  }

  /// Groups ingredients into shopping aisle categories
  static String categorize(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // Produce
    if (lower.contains('tomato') ||
        lower.contains('onion') ||
        lower.contains('potato') ||
        lower.contains('spinach') ||
        lower.contains('palak') ||
        lower.contains('coriander') ||
        lower.contains('cilantro') ||
        lower.contains('ginger') ||
        lower.contains('garlic') ||
        lower.contains('chilli') ||
        lower.contains('chili') ||
        lower.contains('lemon') ||
        lower.contains('lime') ||
        lower.contains('carrot') ||
        lower.contains('peas') ||
        lower.contains('capsicum') ||
        lower.contains('bell pepper') ||
        lower.contains('mint') ||
        lower.contains('pudina') ||
        lower.contains('cauliflower') ||
        lower.contains('cabbage') ||
        lower.contains('mushroom') ||
        lower.contains('methi')) {
      return 'Fresh Produce';
    }

    // Dairy
    if (lower.contains('paneer') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('milk') ||
        lower.contains('curd') ||
        lower.contains('yogurt') ||
        lower.contains('ghee') ||
        lower.contains('cheese') ||
        lower.contains('buttermilk')) {
      return 'Dairy & Refrigerated';
    }

    // Grains, Dal & Staples
    if (lower.contains('rice') ||
        lower.contains('dal') ||
        lower.contains('dhal') ||
        lower.contains('lentil') ||
        lower.contains('toor') ||
        lower.contains('moong') ||
        lower.contains('chana') ||
        lower.contains('urad') ||
        lower.contains('atta') ||
        lower.contains('flour') ||
        lower.contains('maida') ||
        lower.contains('besan') ||
        lower.contains('sooji') ||
        lower.contains('semolina') ||
        lower.contains('poha') ||
        lower.contains('quinoa') ||
        lower.contains('bread') ||
        lower.contains('pasta') ||
        lower.contains('noodle')) {
      return 'Grains & Staples';
    }

    // Spices & Seasoning
    if (lower.contains('cumin') ||
        lower.contains('jeera') ||
        lower.contains('turmeric') ||
        lower.contains('haldi') ||
        lower.contains('masala') ||
        lower.contains('mustard') ||
        lower.contains('rai') ||
        lower.contains('hing') ||
        lower.contains('asafoetida') ||
        lower.contains('cardamom') ||
        lower.contains('cinnamon') ||
        lower.contains('clove') ||
        lower.contains('salt') ||
        lower.contains('pepper') ||
        RegExp(r'\boil\b').hasMatch(lower) ||
        lower.contains('curry leaves') ||
        lower.contains('kasuri methi')) {
      return 'Spices & Seasoning';
    }

    return 'Other Groceries';
  }

  /// 9 Official Sprout Grocery Aisle Categories as per UX audit
  static const List<String> groceryCategories = [
    'Fresh Produce',
    'Dairy',
    'Grains & Pantry',
    'Herbs & Spices',
    'Meat & Seafood',
    'Frozen',
    'Condiments & Sauces',
    'Beverages',
    'Other',
  ];

  /// Categorizes ingredients into the 9 official Sprout shopping aisle categories
  static String categorizeGrocery(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // 1. Meat & Seafood
    if (lower.contains('chicken') ||
        lower.contains('mutton') ||
        lower.contains('lamb') ||
        lower.contains('fish') ||
        lower.contains('prawn') ||
        lower.contains('shrimp') ||
        lower.contains('egg') ||
        lower.contains('meat') ||
        lower.contains('pork') ||
        lower.contains('beef')) {
      return 'Meat & Seafood';
    }

    // 2. Frozen
    if (lower.contains('frozen') ||
        lower.contains('ice cream') ||
        lower.contains('ice-cream') ||
        lower.contains('ice cube')) {
      return 'Frozen';
    }

    // 3. Beverages
    if (lower.contains('coconut water') ||
        lower.contains('toddy') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('juice') ||
        lower.contains('soda')) {
      return 'Beverages';
    }

    // 4. Dairy
    if (lower.contains('paneer') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('milk') ||
        lower.contains('curd') ||
        lower.contains('yogurt') ||
        lower.contains('ghee') ||
        lower.contains('cheese') ||
        lower.contains('buttermilk') ||
        lower.contains('malai') ||
        lower.contains('dahi')) {
      return 'Dairy';
    }

    // 5. Herbs & Spices
    if (lower.contains('cumin') ||
        lower.contains('jeera') ||
        lower.contains('turmeric') ||
        lower.contains('haldi') ||
        lower.contains('masala') ||
        lower.contains('mustard') ||
        lower.contains('rai') ||
        lower.contains('hing') ||
        lower.contains('asafoetida') ||
        lower.contains('cardamom') ||
        lower.contains('cinnamon') ||
        lower.contains('clove') ||
        lower.contains('pepper') ||
        lower.contains('curry leaves') ||
        lower.contains('kadi patta') ||
        lower.contains('kasuri methi') ||
        lower.contains('bay leaf') ||
        lower.contains('saffron') ||
        lower.contains('nutmeg') ||
        lower.contains('fennel') ||
        lower.contains('saunf') ||
        lower.contains('oregano') ||
        lower.contains('thyme') ||
        lower.contains('basil') ||
        lower.contains('garam masala') ||
        lower.contains('chilli powder') ||
        lower.contains('coriander powder')) {
      return 'Herbs & Spices';
    }

    // 6. Condiments & Sauces
    if (lower.contains('vinegar') ||
        lower.contains('soy sauce') ||
        lower.contains('ketchup') ||
        lower.contains('mayonnaise') ||
        lower.contains('chilli sauce') ||
        lower.contains('pickle') ||
        lower.contains('achar') ||
        lower.contains('jam') ||
        lower.contains('honey') ||
        lower.contains('chutney')) {
      return 'Condiments & Sauces';
    }

    // 7. Grains & Pantry
    if (lower.contains('rice') ||
        lower.contains('dal') ||
        lower.contains('dhal') ||
        lower.contains('lentil') ||
        lower.contains('toor') ||
        lower.contains('moong') ||
        lower.contains('chana') ||
        lower.contains('urad') ||
        lower.contains('atta') ||
        lower.contains('flour') ||
        lower.contains('maida') ||
        lower.contains('besan') ||
        lower.contains('sooji') ||
        lower.contains('semolina') ||
        lower.contains('poha') ||
        lower.contains('quinoa') ||
        lower.contains('bread') ||
        lower.contains('pasta') ||
        lower.contains('noodle') ||
        lower.contains('sugar') ||
        lower.contains('jaggery') ||
        lower.contains('baking powder') ||
        lower.contains('baking soda') ||
        lower.contains('yeast') ||
        lower.contains('salt') ||
        RegExp(r'\boil\b').hasMatch(lower)) {
      return 'Grains & Pantry';
    }

    // 8. Fresh Produce
    if (lower.contains('tomato') ||
        lower.contains('onion') ||
        lower.contains('potato') ||
        lower.contains('spinach') ||
        lower.contains('palak') ||
        lower.contains('coriander') ||
        lower.contains('cilantro') ||
        lower.contains('dhania') ||
        lower.contains('ginger') ||
        lower.contains('adrak') ||
        lower.contains('garlic') ||
        lower.contains('lehsun') ||
        lower.contains('lahsun') ||
        lower.contains('chilli') ||
        lower.contains('chili') ||
        lower.contains('mirch') ||
        lower.contains('lemon') ||
        lower.contains('lime') ||
        lower.contains('carrot') ||
        lower.contains('peas') ||
        lower.contains('capsicum') ||
        lower.contains('bell pepper') ||
        lower.contains('mint') ||
        lower.contains('pudina') ||
        lower.contains('cauliflower') ||
        lower.contains('cabbage') ||
        lower.contains('mushroom') ||
        lower.contains('methi') ||
        lower.contains('drumstick') ||
        lower.contains('sekta ni sing') ||
        lower.contains('cucumber') ||
        lower.contains('eggplant') ||
        lower.contains('brinjal') ||
        lower.contains('lady finger') ||
        lower.contains('bhindi') ||
        lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('mango') ||
        lower.contains('fruit') ||
        lower.contains('vegetable')) {
      return 'Fresh Produce';
    }

    return 'Other';
  }

  /// Normalizes an ingredient to its clean, canonical display name.
  /// Resolves aliases (Dhania Leaves -> Coriander), singular/plural,
  /// and strips preparation instructions.
  static String normalizeGroceryName(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw.trim();

    // 1. Remove surrounding brackets or quotes
    text = text.replaceAll(RegExp(r'''^[\["'\(]+|[\]"'\)]+$'''), '').trim();

    // 2. Strip preparation methods
    text = text.replaceAll(RegExp(
      r'\b(finely chopped|chopped|washed|cooked|peeled|diced|slit|smashed|grated|minced|sliced|crushed|boiled|shredded|to taste|for frying|warm|cold|hot|room temperature)\b',
      caseSensitive: false,
    ), '');

    // 3. Remove quantities, fractions, and units
    text = text.replaceAll(RegExp(
      r'^\s*(\d+[½¼¾⅓⅔⅛]?|[½¼¾⅓⅔⅛]|\d+\s*/\s*\d+|\d+\s*-\s*\d+)\s*(cups?|tbsp|tablespoons?|tsp|teaspoons?|gms?|g|kg|ml|l|litres?|bunch|bunches|pinch|pinches|cloves?|pieces?|small|medium|large)?\b',
      caseSensitive: false,
    ), '');

    // Also remove secondary quantities like "1 small bunch", "2 inch"
    text = text.replaceAll(RegExp(
      r'\b(a small bunch|small bunch|1 bunch|\d+\s*inch|\d+\s*cm)\b',
      caseSensitive: false,
    ), '');

    // 4. Remove leading/trailing commas, dashes, parenthesis remnants
    text = text.replaceAll(RegExp(r'[\(\)\[\],\-–—]'), ' ').trim();
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    final lower = text.toLowerCase();

    // 5. Canonical Indian & Culinary Alias Mapping
    if (lower.contains('dhania') || lower.contains('coriander') || lower.contains('cilantro')) {
      return 'Coriander';
    }
    if (lower.contains('hari mirch') ||
        lower.contains('green chilli') ||
        lower.contains('green chili') ||
        lower.contains('green chilies') ||
        lower.contains('green chillies')) {
      return 'Green Chillies';
    }
    if (lower.contains('lal mirch') || lower.contains('red chilli powder') || lower.contains('red chili powder')) {
      return 'Red Chilli Powder';
    }
    if (lower.contains('cumin seed') || lower.contains('jeera') || lower == 'cumin') {
      return 'Cumin Seeds';
    }
    if (lower.contains('turmeric') || lower.contains('haldi')) {
      return 'Turmeric';
    }
    if (lower.contains('ginger garlic') ||
        lower.contains('ginger-garlic') ||
        lower.contains('adrak lehsun') ||
        lower.contains('adrak lahsun')) {
      return 'Ginger Garlic Paste';
    }
    if (lower.contains('adrak') || lower.contains('ginger')) {
      return 'Ginger';
    }
    if (lower.contains('lehsun') || lower.contains('lahsun') || lower.contains('garlic')) {
      return 'Garlic';
    }
    if (lower.contains('pyaz') || lower.contains('kanda') || lower.contains('onion')) {
      return 'Onion';
    }
    if (lower.contains('aloo') || lower.contains('batata') || lower.contains('potato')) {
      return 'Potato';
    }
    if (lower.contains('tamatar') || lower.contains('tomato')) {
      return 'Tomato';
    }
    if (lower.contains('palak') || lower.contains('spinach')) {
      return 'Spinach';
    }
    if (lower.contains('kasuri methi')) {
      return 'Kasuri Methi';
    }
    if (lower.contains('methi') || lower.contains('fenugreek')) {
      return 'Fenugreek Leaves';
    }
    if (lower.contains('curry leaves') || lower.contains('kadi patta')) {
      return 'Curry Leaves';
    }
    if (lower.contains('pudina') || lower.contains('mint')) {
      return 'Mint Leaves';
    }
    if (lower.contains('mustard seed') || lower.contains('rai') || lower.contains('sarson')) {
      return 'Mustard Seeds';
    }
    if (lower.contains('asafoetida') || lower.contains('hing')) {
      return 'Hing (Asafoetida)';
    }
    if (lower.contains('cardamom') || lower.contains('elaichi')) {
      return 'Cardamom';
    }
    if (lower.contains('cinnamon') || lower.contains('dalchini')) {
      return 'Cinnamon';
    }
    if (lower.contains('clove') || lower.contains('laung')) {
      return 'Cloves';
    }
    if (lower.contains('coconut water') || lower.contains('toddy')) {
      return 'Coconut Water';
    }
    if (lower.contains('sekta ni sing') || lower.contains('drumstick')) {
      return 'Drumsticks';
    }
    if (lower.contains('paneer')) {
      return 'Paneer';
    }
    if (lower.contains('ghee')) {
      return 'Ghee';
    }
    if (lower.contains('butter') || lower.contains('makhan')) {
      return 'Butter';
    }
    if (lower.contains('curd') || lower.contains('yogurt') || lower.contains('dahi')) {
      return 'Curd / Yogurt';
    }
    if (lower.contains('milk')) {
      return 'Milk';
    }
    if (lower.contains('basmati rice') || lower == 'rice') {
      return 'Rice';
    }
    if (lower.contains('toor dal') || lower.contains('tuvar dal')) {
      return 'Toor Dal';
    }
    if (lower.contains('moong dal')) {
      return 'Moong Dal';
    }
    if (lower.contains('chana dal')) {
      return 'Chana Dal';
    }
    if (lower.contains('atta') || lower.contains('wheat flour')) {
      return 'Wheat Flour (Atta)';
    }
    if (lower.contains('maida') || lower.contains('all purpose flour')) {
      return 'All-Purpose Flour (Maida)';
    }
    if (lower.contains('besan') || lower.contains('gram flour')) {
      return 'Gram Flour (Besan)';
    }
    if (lower.contains('sooji') || lower.contains('rava') || lower.contains('semolina')) {
      return 'Semolina (Sooji)';
    }
    if (lower.contains('poha')) {
      return 'Poha';
    }

    // Capitalize first letter cleanly
    if (text.isNotEmpty) {
      return text[0].toUpperCase() + text.substring(1);
    }
    return raw.trim();
  }

  /// Parses quantity, unit, and details from an ingredient string.
  /// Example: "½ cup Coriander (Dhania) Leaves, a small bunch finely chopped"
  /// Returns: ParsedIngredient(primaryName: "Coriander", displayQuantity: "½ cup · 1 small bunch", ...)
  static ParsedIngredient parseIngredient(String raw) {
    final normalized = normalize(raw);
    final primary = normalizeGroceryName(raw);

    // Extract quantity and unit
    double? numericAmount;
    String? unit;
    String quantityDisplay = '';

    final numMatch = RegExp(
      r'(\d+[½¼¾⅓⅔⅛]?|[½¼¾⅓⅔⅛]|\d+\s*/\s*\d+)\s*(cups?|tbsp|tsp|tablespoons?|teaspoons?|gms?|g|kg|ml|l|litres?|bunches?|bunch|pinches?|pinch|cloves?|pieces?)?',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (numMatch != null) {
      final amountStr = numMatch.group(1)?.trim() ?? '';
      numericAmount = _parseFractionValue(amountStr);
      final rawUnit = numMatch.group(2)?.trim().toLowerCase();
      if (rawUnit != null && rawUnit.isNotEmpty) {
        if (rawUnit.startsWith('cup')) {
          unit = 'cup';
        } else if (rawUnit.startsWith('tbsp') || rawUnit.startsWith('tablespoon')) {
          unit = 'tbsp';
        } else if (rawUnit.startsWith('tsp') || rawUnit.startsWith('teaspoon')) {
          unit = 'tsp';
        } else if (rawUnit == 'g' || rawUnit.startsWith('gm')) {
          unit = 'g';
        } else if (rawUnit == 'kg') {
          unit = 'kg';
        } else if (rawUnit == 'ml') {
          unit = 'ml';
        } else if (rawUnit == 'l' || rawUnit.startsWith('litre')) {
          unit = 'L';
        } else if (rawUnit.startsWith('bunch')) {
          unit = 'bunch';
        } else if (rawUnit.startsWith('clove')) {
          unit = 'cloves';
        } else {
          unit = rawUnit;
        }
      }

      quantityDisplay = amountStr;
      if (unit != null) {
        quantityDisplay += (numericAmount != null && numericAmount > 1 && unit == 'cup')
            ? ' cups'
            : ' $unit';
      }
    }

    // Secondary detail note (e.g. "1 small bunch", "a pinch")
    final bunchMatch = RegExp(r'\b(a small bunch|small bunch|1 bunch)\b', caseSensitive: false).firstMatch(normalized);
    if (bunchMatch != null) {
      final bunchNote = '1 small bunch';
      if (quantityDisplay.isNotEmpty && !quantityDisplay.contains('bunch')) {
        quantityDisplay = '$quantityDisplay · $bunchNote';
      } else if (quantityDisplay.isEmpty) {
        quantityDisplay = bunchNote;
      }
    }

    // Default quantity display if none found
    if (quantityDisplay.isEmpty) {
      quantityDisplay = 'As needed';
    }

    final category = categorizeGrocery(primary.isNotEmpty ? primary : raw);

    return ParsedIngredient(
      primaryName: primary.isNotEmpty ? primary : raw.trim(),
      displayQuantity: quantityDisplay,
      numericAmount: numericAmount,
      unit: unit,
      category: category,
    );
  }

  static double? _parseFractionValue(String str) {
    try {
      final s = str.trim();
      double total = 0.0;
      String rem = s;

      final wholeMatch = RegExp(r'^(\d+)\s*').firstMatch(rem);
      if (wholeMatch != null && wholeMatch.group(1) != null) {
        total += double.tryParse(wholeMatch.group(1)!) ?? 0.0;
        rem = rem.substring(wholeMatch.end).trim();
      }

      if (rem.contains('½')) {
        total += 0.5;
      } else if (rem.contains('¼')) {
        total += 0.25;
      } else if (rem.contains('¾')) {
        total += 0.75;
      } else if (rem.contains('⅓')) {
        total += 0.333;
      } else if (rem.contains('⅔')) {
        total += 0.667;
      } else if (rem.contains('⅛')) {
        total += 0.125;
      } else if (rem.contains('/')) {
        final parts = rem.split('/');
        if (parts.length == 2) {
          final n = double.tryParse(parts[0].trim());
          final d = double.tryParse(parts[1].trim());
          if (n != null && d != null && d != 0) {
            total += n / d;
          }
        }
      }

      return total > 0 ? total : null;
    } catch (_) {
      return null;
    }
  }

  /// Formats combined numeric amount and unit into clean unicode fraction (e.g. 1.5 cup -> 1½ cups)
  static String formatCombinedQuantity(double amount, String? unit) {
    final whole = amount.floor();
    final frac = amount - whole;
    String fracStr = '';
    if ((frac - 0.5).abs() < 0.08) {
      fracStr = '½';
    } else if ((frac - 0.25).abs() < 0.08) {
      fracStr = '¼';
    } else if ((frac - 0.75).abs() < 0.08) {
      fracStr = '¾';
    } else if ((frac - 0.33).abs() < 0.08) {
      fracStr = '⅓';
    } else if ((frac - 0.67).abs() < 0.08) {
      fracStr = '⅔';
    } else if ((frac - 0.125).abs() < 0.08) {
      fracStr = '⅛';
    } else if (frac > 0.08) {
      fracStr = frac.toStringAsFixed(1);
    }

    String numPart = '';
    if (whole > 0 && fracStr.isNotEmpty) {
      numPart = '$whole$fracStr';
    } else if (whole > 0) {
      numPart = '$whole';
    } else if (fracStr.isNotEmpty) {
      numPart = fracStr;
    }

    final u = unit ?? '';
    final pluralUnit = (amount > 1 && u == 'cup') ? 'cups' : u;
    if (pluralUnit.isEmpty) return numPart;
    return '$numPart $pluralUnit';
  }

  /// Returns category emoji prefix supporting both standard 9 categories and legacy categories
  static String getCategoryEmoji(String category) {
    switch (category) {
      case 'Fresh Produce':
        return '🥬';
      case 'Dairy':
      case 'Dairy & Refrigerated':
        return '🥛';
      case 'Grains & Pantry':
      case 'Grains & Staples':
        return '🌾';
      case 'Herbs & Spices':
        return '🌿';
      case 'Spices & Seasoning':
      case 'Spices & Seasonings':
        return '🧂';
      case 'Meat & Seafood':
        return '🍗';
      case 'Frozen':
        return '🧊';
      case 'Condiments & Sauces':
        return '🍯';
      case 'Beverages':
        return '🧃';
      case 'Other':
      case 'Other Groceries':
      default:
        return '📦';
    }
  }
}

/// Represents a parsed grocery item with primary canonical name and extracted quantity
class ParsedIngredient {
  final String primaryName;
  final String displayQuantity;
  final double? numericAmount;
  final String? unit;
  final String category;

  const ParsedIngredient({
    required this.primaryName,
    required this.displayQuantity,
    this.numericAmount,
    this.unit,
    required this.category,
  });
}
