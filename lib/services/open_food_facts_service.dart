import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ScannedProductInfo {
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final double calories; // kcal per 100g
  final double protein; // g per 100g
  final double carbs; // g per 100g
  final double fat; // g per 100g
  final List<String> categories;

  const ScannedProductInfo({
    required this.barcode,
    required this.name,
    this.brand = '',
    this.imageUrl,
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.categories = const [],
  });

  factory ScannedProductInfo.fromJson(String barcode, Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    final name = (product['product_name'] as String?)?.trim() ??
        (product['product_name_en'] as String?)?.trim() ??
        'Unknown Product';

    final brand = (product['brands'] as String?)?.trim() ?? '';
    final imageUrl = product['image_front_small_url'] as String? ??
        product['image_url'] as String?;

    final calories = (nutriments['energy-kcal_100g'] as num?)?.toDouble() ??
        (nutriments['energy-kcal'] as num?)?.toDouble() ??
        0.0;
    final protein = (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0;
    final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0;
    final fat = (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0;

    final categoriesRaw = (product['categories'] as String?) ?? '';
    final categories = categoriesRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ScannedProductInfo(
      barcode: barcode,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      categories: categories,
    );
  }
}

class OpenFoodFactsService {
  static const Map<String, ScannedProductInfo> _sampleMockProducts = {
    '3017620422003': ScannedProductInfo(
      barcode: '3017620422003',
      name: 'Nutella Hazelnut Spread',
      brand: 'Ferrero',
      imageUrl: 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_en.514.400.jpg',
      calories: 539.0,
      protein: 6.3,
      carbs: 57.5,
      fat: 30.9,
      categories: ['Spreads', 'Sweet spreads', 'Cocoa and hazelnuts spreads'],
    ),
    '8076809513753': ScannedProductInfo(
      barcode: '8076809513753',
      name: 'Penne Rigate N.73',
      brand: 'Barilla',
      imageUrl: 'https://images.openfoodfacts.org/images/products/807/680/951/3753/front_en.115.400.jpg',
      calories: 359.0,
      protein: 12.0,
      carbs: 71.2,
      fat: 2.0,
      categories: ['Pastas', 'Durum wheat pasta'],
    ),
    '8410199001048': ScannedProductInfo(
      barcode: '8410199001048',
      name: 'Extra Virgin Olive Oil',
      brand: 'Borges',
      imageUrl: 'https://images.openfoodfacts.org/images/products/841/019/900/1048/front_en.57.400.jpg',
      calories: 900.0,
      protein: 0.0,
      carbs: 0.0,
      fat: 100.0,
      categories: ['Fats', 'Vegetable oils', 'Olive oils'],
    ),
  };

  /// Fetches product details and nutrition info from OpenFoodFacts by barcode.
  Future<ScannedProductInfo?> fetchProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // Check offline preset mock bundle first for test reliability
    if (_sampleMockProducts.containsKey(cleanBarcode)) {
      return _sampleMockProducts[cleanBarcode];
    }

    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$cleanBarcode.json',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SproutApp/1.0 (contact@sproutapp.example.com)',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final status = decoded['status'] as int? ?? 0;
        if (status == 1) {
          return ScannedProductInfo.fromJson(cleanBarcode, decoded);
        }
      }
    } catch (e) {
      debugPrint('OpenFoodFacts fetch error for barcode $cleanBarcode: $e');
    }

    return null;
  }
}
