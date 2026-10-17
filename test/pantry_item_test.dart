import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/models/pantry_item.dart';

void main() {
  group('PantryItem Model & Freshness Tests', () {
    test('freshness is fresh when expiresAt is null', () {
      final item = PantryItem(
        id: '1',
        name: 'Salt',
        addedAt: DateTime.now(),
      );
      expect(item.freshness, PantryFreshness.fresh);
      expect(item.daysRemaining, 999);
    });

    test('freshness is fresh when expiresAt is 5 days away', () {
      final now = DateTime.now();
      final item = PantryItem(
        id: '2',
        name: 'Apples',
        addedAt: now,
        expiresAt: now.add(const Duration(days: 5)),
      );
      expect(item.freshness, PantryFreshness.fresh);
      expect(item.daysRemaining, 5);
    });

    test('freshness is expiringSoon when expiresAt is 2 days away or less', () {
      final now = DateTime.now();
      final item = PantryItem(
        id: '3',
        name: 'Milk',
        addedAt: now,
        expiresAt: now.add(const Duration(days: 1)),
      );
      expect(item.freshness, PantryFreshness.expiringSoon);
      expect(item.daysRemaining, 1);
    });

    test('freshness is expired when expiresAt is in the past', () {
      final now = DateTime.now();
      final item = PantryItem(
        id: '4',
        name: 'Spinach',
        addedAt: now.subtract(const Duration(days: 5)),
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(item.freshness, PantryFreshness.expired);
      expect(item.daysRemaining, -1);
    });

    test('JSON serialization roundtrip works correctly', () {
      final now = DateTime.now();
      final original = PantryItem(
        id: 'item_101',
        name: 'Extra Virgin Olive Oil',
        category: 'Oils',
        addedAt: now,
        expiresAt: now.add(const Duration(days: 30)),
        quantity: '500ml',
      );

      final json = original.toJson();
      final reconstructed = PantryItem.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.category, original.category);
      expect(reconstructed.quantity, original.quantity);
      expect(reconstructed.expiresAt?.day, original.expiresAt?.day);
    });
  });
}
