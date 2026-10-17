class ShoppingItem {
  final String id;
  final String name;
  final String? displayQuantity;
  final String? recipeTitle;
  final int recipeCount;
  final String? category;
  final double? numericAmount;
  final String? unit;
  final bool isBought;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.displayQuantity,
    this.recipeTitle,
    this.recipeCount = 1,
    this.category,
    this.numericAmount,
    this.unit,
    this.isBought = false,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? displayQuantity,
    String? recipeTitle,
    int? recipeCount,
    String? category,
    double? numericAmount,
    String? unit,
    bool? isBought,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipeCount: recipeCount ?? this.recipeCount,
      category: category ?? this.category,
      numericAmount: numericAmount ?? this.numericAmount,
      unit: unit ?? this.unit,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_quantity': displayQuantity,
      'recipe_title': recipeTitle,
      'recipe_count': recipeCount,
      'category': category,
      'numeric_amount': numericAmount,
      'unit': unit,
      'is_bought': isBought,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? json['ingredient'] ?? '',
      displayQuantity: json['display_quantity'],
      recipeTitle: json['recipe_title'],
      recipeCount: (json['recipe_count'] as num?)?.toInt() ?? 1,
      category: json['category'],
      numericAmount: (json['numeric_amount'] as num?)?.toDouble(),
      unit: json['unit'],
      isBought: json['is_bought'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

