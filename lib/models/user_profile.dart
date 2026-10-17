class UserProfile {
  final String id;
  final String displayName;
  final List<String> dietaryPreferences;
  final int savedCount;
  final int cookedCount;
  final int collectionsCount;

  const UserProfile({
    required this.id,
    this.displayName = 'Chef',
    this.dietaryPreferences = const [],
    this.savedCount = 0,
    this.cookedCount = 0,
    this.collectionsCount = 0,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    List<String>? dietaryPreferences,
    int? savedCount,
    int? cookedCount,
    int? collectionsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      savedCount: savedCount ?? this.savedCount,
      cookedCount: cookedCount ?? this.cookedCount,
      collectionsCount: collectionsCount ?? this.collectionsCount,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name'] ?? 'Chef',
      dietaryPreferences: (json['dietary_preferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      savedCount: (json['saved_count'] as num?)?.toInt() ?? 0,
      cookedCount: (json['cooked_count'] as num?)?.toInt() ?? 0,
      collectionsCount: (json['collections_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'dietary_preferences': dietaryPreferences,
    };
  }
}
