enum PantryFreshness {
  fresh,
  expiringSoon,
  expired,
}

class PantryItem {
  final String id;
  final String name;
  final String category;
  final DateTime addedAt;
  final DateTime? expiresAt;
  final String quantity;

  const PantryItem({
    required this.id,
    required this.name,
    this.category = 'Pantry',
    required this.addedAt,
    this.expiresAt,
    this.quantity = '1 item',
  });

  int get daysRemaining {
    if (expiresAt == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return expiryDay.difference(today).inDays;
  }

  PantryFreshness get freshness {
    if (expiresAt == null) return PantryFreshness.fresh;
    final days = daysRemaining;
    if (days < 0) return PantryFreshness.expired;
    if (days <= 2) return PantryFreshness.expiringSoon;
    return PantryFreshness.fresh;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'addedAt': addedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'quantity': quantity,
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Pantry',
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      quantity: json['quantity'] as String? ?? '1 item',
    );
  }

  PantryItem copyWith({
    String? name,
    String? category,
    DateTime? expiresAt,
    String? quantity,
  }) {
    return PantryItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      addedAt: addedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      quantity: quantity ?? this.quantity,
    );
  }
}
