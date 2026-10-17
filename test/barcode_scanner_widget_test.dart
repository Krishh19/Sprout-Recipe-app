import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/scanner/widgets/scanned_product_sheet.dart';
import 'package:sprout/services/open_food_facts_service.dart';

void main() {
  testWidgets('ScannedProductSheet renders product name, barcode, and macros correctly', (tester) async {
    const product = ScannedProductInfo(
      barcode: '8076809513753',
      name: 'Penne Rigate N.73',
      brand: 'Barilla',
      calories: 359.0,
      protein: 12.0,
      carbs: 71.2,
      fat: 2.0,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ScannedProductSheet(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Penne Rigate N.73'), findsOneWidget);
    expect(find.text('BARILLA'), findsOneWidget);
    expect(find.text('UPC: 8076809513753'), findsOneWidget);
    expect(find.text('359 kcal'), findsOneWidget);
    expect(find.text('12.0g'), findsOneWidget);
    expect(find.text('Add to Pantry'), findsOneWidget);
    expect(find.text('Add to List'), findsOneWidget);
  });
}
