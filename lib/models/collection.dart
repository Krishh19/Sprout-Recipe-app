class RecipeCollection {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String icon;
  final int recipeCount;
  final String? coverImageUrl;
  final DateTime createdAt;

  const RecipeCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.icon = 'bookmark',
    this.recipeCount = 0,
    this.coverImageUrl,
    required this.createdAt,
  });

  factory RecipeCollection.fromJson(Map<String, dynamic> json) {
    return RecipeCollection(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] ?? 'Collection',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'bookmark',
      recipeCount: (json['recipe_count'] as num?)?.toInt() ?? 0,
      coverImageUrl: json['cover_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}
