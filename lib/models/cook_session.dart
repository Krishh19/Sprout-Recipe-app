import 'recipe.dart';

/// A snapshot of an in-progress cooking session so the user can
/// leave and resume later exactly where they left off.
class CookSession {
  final Recipe recipe;
  final int currentStep;

  const CookSession({required this.recipe, required this.currentStep});

  Map<String, dynamic> toJson() => {
        'recipe': recipe.toJson(),
        'current_step': currentStep,
      };

  factory CookSession.fromJson(Map<String, dynamic> json) {
    return CookSession(
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      currentStep: (json['current_step'] as num?)?.toInt() ?? 0,
    );
  }
}
