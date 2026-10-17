import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/models/cook_history_item.dart';

void main() {
  group('CookHistoryItem Tests', () {
    test('serializes to and from JSON accurately', () {
      final now = DateTime.now();
      final item = CookHistoryItem(
        id: 'cook-1',
        recipeId: 'rec-123',
        recipeTitle: 'Paneer Butter Masala',
        cuisine: 'North Indian',
        totalTimeMins: 30,
        recipeImageUrl: 'https://example.com/paneer.jpg',
        cookedAt: now,
      );

      final json = item.toJson();
      expect(json['id'], 'cook-1');
      expect(json['recipe_id'], 'rec-123');
      expect(json['title'], 'Paneer Butter Masala');
      expect(json['cuisine'], 'North Indian');
      expect(json['total_time_mins'], 30);

      final reconstructed = CookHistoryItem.fromJson(json);
      expect(reconstructed.id, 'cook-1');
      expect(reconstructed.recipeId, 'rec-123');
      expect(reconstructed.recipeTitle, 'Paneer Butter Masala');
      expect(reconstructed.cuisine, 'North Indian');
      expect(reconstructed.recipeImageUrl, 'https://example.com/paneer.jpg');
      expect(reconstructed.totalTimeMins, 30);
    });
  });
}
