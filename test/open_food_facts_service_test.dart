import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/services/open_food_facts_service.dart';

void main() {
  group('OpenFoodFactsService Tests', () {
    final service = OpenFoodFactsService();

    test('fetches preset barcode for Barilla Pasta with correct macros', () async {
      final product = await service.fetchProductByBarcode('8076809513753');
      expect(product, isNotNull);
      expect(product!.name, 'Penne Rigate N.73');
      expect(product.brand, 'Barilla');
      expect(product.calories, 359.0);
      expect(product.protein, 12.0);
      expect(product.carbs, 71.2);
      expect(product.categories, contains('Pastas'));
    });

    test('fetches preset barcode for Nutella with correct macros', () async {
      final product = await service.fetchProductByBarcode('3017620422003');
      expect(product, isNotNull);
      expect(product!.name, 'Nutella Hazelnut Spread');
      expect(product.brand, 'Ferrero');
      expect(product.calories, 539.0);
      expect(product.fat, 30.9);
    });

    test('returns null for empty barcode', () async {
      final product = await service.fetchProductByBarcode('');
      expect(product, isNull);
    });

    test('parses ScannedProductInfo from OpenFoodFacts JSON payload', () {
      final json = {
        'product': {
          'product_name': 'Organic Rolled Oats',
          'brands': 'Bob\'s Red Mill',
          'image_url': 'https://example.com/oats.jpg',
          'categories': 'Breakfast, Cereals, Oats',
          'nutriments': {
            'energy-kcal_100g': 379,
            'proteins_100g': 13.2,
            'carbohydrates_100g': 67.7,
            'fat_100g': 6.5,
          }
        }
      };

      final parsed = ScannedProductInfo.fromJson('039978001153', json);
      expect(parsed.name, 'Organic Rolled Oats');
      expect(parsed.brand, 'Bob\'s Red Mill');
      expect(parsed.calories, 379.0);
      expect(parsed.protein, 13.2);
      expect(parsed.carbs, 67.7);
      expect(parsed.fat, 6.5);
      expect(parsed.categories, ['Breakfast', 'Cereals', 'Oats']);
    });
  });
}
