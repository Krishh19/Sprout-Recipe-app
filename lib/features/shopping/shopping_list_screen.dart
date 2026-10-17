import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/sprout_ingredient_formatter.dart';
import '../../design/typography.dart';
import '../../models/shopping_item.dart';
import '../../providers/app_providers.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  bool _isPurchasedExpanded = false;

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      ref.read(shoppingListProvider.notifier).addItems([text]);
      _itemController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingState = ref.watch(shoppingListProvider);
    final items = shoppingState.value ?? [];
    final unboughtItems = items.where((i) => !i.isBought).toList();
    final boughtItems = items.where((i) => i.isBought).toList();

    // Group unbought by aisle category
    final Map<String, List<ShoppingItem>> categorized = {};
    for (final item in unboughtItems) {
      final cat = item.category ?? SproutIngredientFormatter.categorizeGrocery(item.name);
      categorized.putIfAbsent(cat, () => []).add(item);
    }

    final categoryOrder = SproutIngredientFormatter.groceryCategories;

    return SproutScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  SproutBouncyTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SproutColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SproutColors.sage.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grocery List', style: SproutTypography.h3()),
                        Text(
                          '${unboughtItems.length} items to pick up',
                          style: SproutTypography.caption(color: SproutColors.secondaryInk),
                        ),
                      ],
                    ),
                  ),
                  if (boughtItems.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(shoppingListProvider.notifier).clearBought();
                      },
                      child: Text(
                        'Clear Done',
                        style: SproutTypography.smallBold(color: SproutColors.tomato),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0x1F8DA399)),

            // Body: Empty State or Categorized Items List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: SproutEmptyState(
                        imageAsset: SproutAssets.emptyShopping,
                        imageHeight: 130,
                        title: 'Grocery List Empty',
                        subtitle: 'Tap "Add to Shopping List" on recipe cards to organize your grocery run.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        // If all unbought items are checked off but bought items exist
                        if (unboughtItems.isEmpty && boughtItems.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SproutColors.sproutGreen.withValues(alpha: 0.1),
                              borderRadius: SproutRadii.card,
                              border: Border.all(
                                color: SproutColors.sproutGreen.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'All groceries picked up!',
                                        style: SproutTypography.bodyBold(color: SproutColors.primaryInk),
                                      ),
                                      Text(
                                        'Your kitchen is ready to cook.',
                                        style: SproutTypography.caption(color: SproutColors.secondaryInk),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Categorized Unbought Items
                        for (final cat in categoryOrder)
                          if (categorized[cat]?.isNotEmpty == true) ...[
                            _buildCategoryHeader(cat, categorized[cat]!.length),
                            const SizedBox(height: 8),
                            ...categorized[cat]!.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildItemRow(item),
                                )),
                            const SizedBox(height: 12),
                          ],

                        // Collapsible Purchased Section
                        if (boughtItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _isPurchasedExpanded = !_isPurchasedExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: SproutColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: SproutColors.sage.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: SproutColors.sproutGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Purchased (${boughtItems.length})',
                                    style: SproutTypography.bodyBold(color: SproutColors.secondaryInk),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _isPurchasedExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: SproutColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isPurchasedExpanded) ...[
                            const SizedBox(height: 8),
                            ...boughtItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildItemRow(item),
                                )),
                          ],
                        ],
                      ],
                    ),
            ),

            // Quick Add Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: SproutColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        hintText: 'Add ingredient or grocery item...',
                        hintStyle: SproutTypography.body(color: SproutColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: SproutColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SproutBouncyTap(
                    onTap: _addItem,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SproutColors.sproutGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String category, int count) {
    final emoji = SproutIngredientFormatter.getCategoryEmoji(category);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$emoji  $category',
            style: SproutTypography.smallBold(color: SproutColors.secondaryInk),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: SproutColors.sage.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: SproutTypography.caption(
                color: SproutColors.primaryInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Dismissible(
      key: ValueKey('shopping_${item.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: SproutColors.sproutGreen,
          borderRadius: SproutRadii.card,
        ),
        child: Row(
          children: [
            Icon(
              item.isBought ? Icons.replay_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              item.isBought ? 'Mark Active' : 'Mark Bought',
              style: SproutTypography.caption(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: SproutColors.tomato,
          borderRadius: SproutRadii.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Remove',
              style: SproutTypography.caption(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          ref.read(shoppingListProvider.notifier).toggleBought(item.id);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.heavyImpact();
          final deletedItem = item;
          ref.read(shoppingListProvider.notifier).removeItem(item.id);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${deletedItem.name}" from shopping list'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: SproutColors.sproutGreen,
                onPressed: () {
                  ref.read(shoppingListProvider.notifier).addItem(
                        deletedItem.name,
                        recipeTitle: deletedItem.recipeTitle,
                      );
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: item.isBought
              ? SproutColors.sproutGreen.withValues(alpha: 0.05)
              : SproutColors.surface,
          borderRadius: SproutRadii.card,
          border: Border.all(
            color: item.isBought
                ? SproutColors.sproutGreen.withValues(alpha: 0.2)
                : SproutColors.sage.withValues(alpha: 0.15),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SproutRadii.card,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(shoppingListProvider.notifier).toggleBought(item.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Custom Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.isBought ? SproutColors.sproutGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: item.isBought ? SproutColors.sproutGreen : SproutColors.muted,
                        width: 1.8,
                      ),
                    ),
                    child: item.isBought
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Name & Recipe Origin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Canonical Ingredient Name
                        Text(
                          item.name,
                          style: SproutTypography.body(
                            fontWeight: FontWeight.w700,
                            color: item.isBought ? SproutColors.muted : SproutColors.primaryInk,
                          ).copyWith(
                            fontSize: 15,
                            decoration: item.isBought ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Secondary Quantity & Source Meta Row
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.displayQuantity != null && item.displayQuantity!.isNotEmpty)
                              Text(
                                item.displayQuantity!,
                                style: SproutTypography.caption(
                                  color: item.isBought ? SproutColors.muted : SproutColors.secondaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (item.displayQuantity != null &&
                                item.displayQuantity!.isNotEmpty &&
                                ((item.recipeCount > 1) || (item.recipeTitle != null && item.recipeTitle!.isNotEmpty)))
                              Text(
                                '·',
                                style: SproutTypography.caption(color: SproutColors.muted),
                              ),
                            if (item.recipeCount > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: SproutColors.sproutGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Used in ${item.recipeCount} recipes',
                                  style: SproutTypography.caption(
                                    color: SproutColors.sproutGreen,
                                    fontWeight: FontWeight.w700,
                                  ).copyWith(fontSize: 11),
                                ),
                              )
                            else if (item.recipeTitle != null && item.recipeTitle!.isNotEmpty)
                              Text(
                                item.recipeTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SproutTypography.caption(
                                  color: SproutColors.secondaryInk,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Icon
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: SproutColors.muted),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(shoppingListProvider.notifier).removeItem(item.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

