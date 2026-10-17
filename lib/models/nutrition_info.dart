class NutritionInfo {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final String? healthNote;
  final bool isAiEstimated;

  const NutritionInfo({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.healthNote,
    this.isAiEstimated = false,
  });

  NutritionInfo scale(double factor) {
    if (factor == 1.0) return this;
    return NutritionInfo(
      calories: (calories * factor).round(),
      proteinG: (proteinG * factor).round(),
      carbsG: (carbsG * factor).round(),
      fatG: (fatG * factor).round(),
      fiberG: (fiberG * factor).round(),
      healthNote: healthNote,
      isAiEstimated: isAiEstimated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'fiberG': fiberG,
      'healthNote': healthNote,
      'isAiEstimated': isAiEstimated,
    };
  }

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num?)?.toInt() ?? 350,
      proteinG: (json['proteinG'] as num? ?? json['protein'] as num?)?.toInt() ?? 12,
      carbsG: (json['carbsG'] as num? ?? json['carbs'] as num?)?.toInt() ?? 30,
      fatG: (json['fatG'] as num? ?? json['fat'] as num?)?.toInt() ?? 14,
      fiberG: (json['fiberG'] as num? ?? json['fiber'] as num?)?.toInt() ?? 4,
      healthNote: json['healthNote'] as String? ?? json['health_note'] as String?,
      isAiEstimated: json['isAiEstimated'] as bool? ?? true,
    );
  }
}
