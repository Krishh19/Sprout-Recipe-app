class CookHistoryItem {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final String? recipeImageUrl;
  final String cuisine;
  final int totalTimeMins;
  final DateTime cookedAt;
  final int rating;
  final String difficulty;

  const CookHistoryItem({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    this.recipeImageUrl,
    required this.cuisine,
    required this.totalTimeMins,
    required this.cookedAt,
    this.rating = 0,
    this.difficulty = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'title': recipeTitle,
      'image_url': recipeImageUrl,
      'cuisine': cuisine,
      'total_time_mins': totalTimeMins,
      'cooked_at': cookedAt.toIso8601String(),
      'rating': rating,
      'difficulty': difficulty,
    };
  }

  factory CookHistoryItem.fromJson(Map<String, dynamic> json) {
    return CookHistoryItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      recipeId: json['recipe_id']?.toString() ?? '',
      recipeTitle: json['title'] ?? json['recipe_title'] ?? 'Delicious Dish',
      recipeImageUrl: json['image_url'] ?? json['recipe_image_url'],
      cuisine: json['cuisine'] ?? 'Indian',
      totalTimeMins: (json['total_time_mins'] as num?)?.toInt() ?? 30,
      cookedAt: json['cooked_at'] != null
          ? DateTime.tryParse(json['cooked_at']) ?? DateTime.now()
          : DateTime.now(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty']?.toString() ?? '',
    );
  }
}
