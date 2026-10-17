class SubstitutionModel {
  final String originalIngredient;
  final String substitute;
  final String culinaryTip;
  final String? rationale;

  const SubstitutionModel({
    required this.originalIngredient,
    required this.substitute,
    required this.culinaryTip,
    this.rationale,
  });

  Map<String, dynamic> toJson() {
    return {
      'original_ingredient': originalIngredient,
      'substitute': substitute,
      'culinary_tip': culinaryTip,
      if (rationale != null) 'rationale': rationale,
    };
  }

  factory SubstitutionModel.fromJson(Map<String, dynamic> json) {
    return SubstitutionModel(
      originalIngredient: json['original_ingredient'] ?? json['original'] ?? json['missing'] ?? '',
      substitute: json['substitute'] ?? json['substitution'] ?? '',
      culinaryTip: json['culinary_tip'] ?? json['tip'] ?? 'Use in equal proportion.',
      rationale: json['rationale'] ?? json['reason'],
    );
  }
}
