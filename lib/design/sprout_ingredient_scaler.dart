/// Utility to intelligently parse and scale ingredient quantities
/// when the user adjusts recipe serving sizes.
class SproutIngredientScaler {
  SproutIngredientScaler._();

  static final RegExp _quantityPattern = RegExp(
    r'^(\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?|\d+/\d+|[½¼¾⅓⅔⅛])\s*([a-zA-Z]+)?\b',
  );

  /// Scales the leading numeric quantity in an ingredient string by [scale].
  /// If no numeric quantity is found (e.g., "Salt to taste"), returns the original string.
  static String scale(String ingredient, double scale) {
    if (scale == 1.0 || ingredient.trim().isEmpty) {
      return ingredient;
    }

    final trimmed = ingredient.trim();

    // Check for leading number or fraction
    final match = _quantityPattern.firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }

    final rawNum = match.group(1)!;
    final unit = match.group(2) ?? '';
    final value = _parseNumber(rawNum);

    if (value == null || value <= 0) {
      return trimmed;
    }

    final scaledValue = value * scale;
    final formattedNum = _formatNumber(scaledValue);

    final rest = trimmed.substring(match.end).trim();
    if (unit.isNotEmpty) {
      return '$formattedNum $unit $rest'.trim();
    } else {
      return '$formattedNum $rest'.trim();
    }
  }

  static double? _parseNumber(String str) {
    str = str.trim();

    // Unicode fractions
    switch (str) {
      case '½':
        return 0.5;
      case '¼':
        return 0.25;
      case '¾':
        return 0.75;
      case '⅓':
        return 1.0 / 3.0;
      case '⅔':
        return 2.0 / 3.0;
      case '⅛':
        return 0.125;
    }

    // Mixed fractions e.g. "1 1/2"
    if (str.contains(' ') && str.contains('/')) {
      final parts = str.split(' ');
      if (parts.length == 2) {
        final whole = double.tryParse(parts[0]);
        final frac = _parseFraction(parts[1]);
        if (whole != null && frac != null) {
          return whole + frac;
        }
      }
    }

    // Simple fraction e.g. "1/2"
    if (str.contains('/')) {
      return _parseFraction(str);
    }

    // Regular double / integer
    return double.tryParse(str);
  }

  static double? _parseFraction(String str) {
    final parts = str.split('/');
    if (parts.length == 2) {
      final num = double.tryParse(parts[0]);
      final den = double.tryParse(parts[1]);
      if (num != null && den != null && den != 0) {
        return num / den;
      }
    }
    return null;
  }

  static String _formatNumber(double val) {
    // If very close to an integer
    final roundedInt = val.round();
    if ((val - roundedInt).abs() < 0.05) {
      return roundedInt.toString();
    }

    // For values >= 10, round to integer (e.g. grams: 250g -> 500g)
    if (val >= 10) {
      return val.round().toString();
    }

    // Check common fractions
    final whole = val.floor();
    final frac = val - whole;

    String? fractionStr;
    if ((frac - 0.25).abs() < 0.06) {
      fractionStr = '¼';
    } else if ((frac - 0.33).abs() < 0.06) {
      fractionStr = '⅓';
    } else if ((frac - 0.5).abs() < 0.06) {
      fractionStr = '½';
    } else if ((frac - 0.66).abs() < 0.06) {
      fractionStr = '⅔';
    } else if ((frac - 0.75).abs() < 0.06) {
      fractionStr = '¾';
    }

    if (fractionStr != null) {
      return whole > 0 ? '$whole $fractionStr' : fractionStr;
    }

    // Fallback: 1 decimal place without trailing zero
    return val.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
