import 'package:flutter/material.dart';

class SproutDietBadge extends StatelessWidget {
  final String diet;
  final double size;

  const SproutDietBadge({
    super.key,
    required this.diet,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isVeg = diet.toLowerCase() == 'veg';
    final isEgg = diet.toLowerCase() == 'egg';
    final color = isVeg
        ? const Color(0xFF2E7D32)
        : (isEgg ? const Color(0xFFE65100) : const Color(0xFFC62828));

    return Semantics(
      label: isVeg ? 'Vegetarian' : (isEgg ? 'Contains Egg' : 'Non-Vegetarian'),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.18),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
