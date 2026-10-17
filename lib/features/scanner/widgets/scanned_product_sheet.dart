import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_button.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_haptics.dart';
import '../../../design/typography.dart';
import '../../../providers/app_providers.dart';
import '../../../services/open_food_facts_service.dart';

class ScannedProductSheet extends ConsumerStatefulWidget {
  final ScannedProductInfo product;

  const ScannedProductSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, ScannedProductInfo product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScannedProductSheet(product: product),
    );
  }

  @override
  ConsumerState<ScannedProductSheet> createState() => _ScannedProductSheetState();
}

class _ScannedProductSheetState extends ConsumerState<ScannedProductSheet> {
  void _addToPantry() async {
    SproutHaptics.success();
    final pantryNotifier = ref.read(pantryProvider.notifier);
    await pantryNotifier.addItems([widget.product.name]);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.product.name}" to your Pantry! 🌱'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToShoppingList() async {
    SproutHaptics.medium();
    final shoppingRepo = ref.read(shoppingRepositoryProvider);
    await shoppingRepo.addItems([widget.product.name]);
    ref.invalidate(shoppingListProvider);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.product.name}" to your Shopping List! 🛒'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: SproutColors.sage.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Product header with image & brand
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: SproutColors.canvas,
                  borderRadius: SproutRadii.borderMd,
                  border: Border.all(
                    color: SproutColors.sage.withValues(alpha: 0.25),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? Image.network(
                        p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fastfood_rounded,
                          size: 32,
                          color: SproutColors.sproutGreen,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood_rounded,
                        size: 32,
                        color: SproutColors.sproutGreen,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.brand.isNotEmpty)
                      Text(
                        p.brand.toUpperCase(),
                        style: SproutTypography.caption(
                          color: SproutColors.secondaryInk,
                          fontWeight: FontWeight.w700,
                        ).copyWith(letterSpacing: 1.0),
                      ),
                    Text(
                      p.name,
                      style: SproutTypography.h3().copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SproutColors.sage.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'UPC: ${p.barcode}',
                        style: SproutTypography.caption(
                          color: SproutColors.secondaryInk,
                          fontWeight: FontWeight.w600,
                        ).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Nutrition Macros Strip
          Text(
            'NUTRITION PER 100G',
            style: SproutTypography.caption(
              color: SproutColors.secondaryInk,
              fontWeight: FontWeight.w700,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroPill('Calories', '${p.calories.toInt()} kcal', SproutColors.tomato),
              const SizedBox(width: 8),
              _buildMacroPill('Protein', '${p.protein.toStringAsFixed(1)}g', SproutColors.sproutGreen),
              const SizedBox(width: 8),
              _buildMacroPill('Carbs', '${p.carbs.toStringAsFixed(1)}g', Colors.amber.shade800),
              const SizedBox(width: 8),
              _buildMacroPill('Fat', '${p.fat.toStringAsFixed(1)}g', Colors.purple.shade400),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: SproutButton(
                  label: 'Add to Pantry',
                  onPressed: _addToPantry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SproutButton(
                  label: 'Add to List',
                  variant: SproutButtonVariant.secondary,
                  onPressed: _addToShoppingList,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SproutTypography.caption(
                color: color,
                fontWeight: FontWeight.w800,
              ).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: SproutTypography.caption(
                color: SproutColors.secondaryInk,
                fontWeight: FontWeight.w500,
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
