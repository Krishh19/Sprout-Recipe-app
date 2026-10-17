import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/models/shopping_item.dart';

void main() {
  group('ShoppingItem Tests', () {
    test('serializes to and from JSON', () {
      final now = DateTime.now();
      final item = ShoppingItem(
        id: 'shop-1',
        name: 'Fresh Spinach',
        recipeTitle: 'Palak Dal',
        isBought: false,
        createdAt: now,
      );

      final json = item.toJson();
      expect(json['name'], 'Fresh Spinach');
      expect(json['recipe_title'], 'Palak Dal');
      expect(json['is_bought'], false);

      final reconstructed = ShoppingItem.fromJson(json);
      expect(reconstructed.id, 'shop-1');
      expect(reconstructed.name, 'Fresh Spinach');
      expect(reconstructed.isBought, false);
    });

    test('copyWith properly toggles bought state', () {
      final item = ShoppingItem(
        id: 'shop-2',
        name: 'Cumin seeds',
        createdAt: DateTime.now(),
      );

      final toggled = item.copyWith(isBought: true);
      expect(toggled.isBought, true);
      expect(toggled.name, 'Cumin seeds');
    });
  });
}
