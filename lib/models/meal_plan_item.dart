import 'recipe.dart';

enum MealType {
  breakfast('Breakfast', '🌅'),
  lunch('Lunch', '☀️'),
  dinner('Dinner', '🌙'),
  snack('Snack', '🍎');

  final String label;
  final String emoji;
  const MealType(this.label, this.emoji);
}

class MealPlanItem {
  final String id;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final MealType mealType;
  final Recipe recipe;
  final String? note;
  final DateTime createdAt;

  const MealPlanItem({
    required this.id,
    required this.dayOfWeek,
    required this.mealType,
    required this.recipe,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'meal_type': mealType.name,
      'recipe': recipe.toJson(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'] as String,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      mealType: MealType.values.firstWhere(
        (m) => m.name == json['meal_type'],
        orElse: () => MealType.dinner,
      ),
      recipe: Recipe.fromJson(Map<String, dynamic>.from(json['recipe'] as Map)),
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  MealPlanItem copyWith({
    String? id,
    int? dayOfWeek,
    MealType? mealType,
    Recipe? recipe,
    String? note,
    DateTime? createdAt,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      recipe: recipe ?? this.recipe,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
