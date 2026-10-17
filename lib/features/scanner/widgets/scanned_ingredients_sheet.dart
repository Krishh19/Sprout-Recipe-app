import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/components/sprout_button.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

class ScannedIngredientsSheet extends StatefulWidget {
  final List<String> initialIngredients;
  final Uint8List? capturedImageBytes;
  final ValueChanged<List<String>> onConfirm;

  const ScannedIngredientsSheet({
    super.key,
    required this.initialIngredients,
    this.capturedImageBytes,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> detectedIngredients,
    Uint8List? capturedImageBytes,
    required ValueChanged<List<String>> onConfirm,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScannedIngredientsSheet(
        initialIngredients: detectedIngredients,
        capturedImageBytes: capturedImageBytes,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ScannedIngredientsSheet> createState() => _ScannedIngredientsSheetState();
}

class _ScannedIngredientsSheetState extends State<ScannedIngredientsSheet> {
  late Set<String> _selectedItems;
  late List<String> _ingredients;
  final TextEditingController _addController = TextEditingController();
  bool _isAddingCustom = false;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.initialIngredients);
    _selectedItems = Set.from(widget.initialIngredients);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _toggleItem(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _removeItem(String item) {
    HapticFeedback.lightImpact();
    setState(() {
      _ingredients.remove(item);
      _selectedItems.remove(item);
    });
  }

  void _addCustomItem() {
    final text = _addController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        if (!_ingredients.contains(text.toLowerCase())) {
          _ingredients.add(text.toLowerCase());
          _selectedItems.add(text.toLowerCase());
        }
        _addController.clear();
        _isAddingCustom = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: SproutColors.sage.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Sheet Header with Mascot
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SproutColors.sproutGreen.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Image.asset(
                      SproutAssets.scanMascotSitting,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Sprout Spotted Items! ✨',
                                style: SproutTypography.h3(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Review detected ingredients and tap any to toggle or remove.',
                          style: SproutTypography.small(
                            color: SproutColors.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Optional Captured Thumbnail Preview Bar
            if (widget.capturedImageBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SproutColors.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: SproutColors.sage.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          widget.capturedImageBytes!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo Analyzed',
                              style: SproutTypography.caption(
                                color: SproutColors.sproutGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_ingredients.length} ingredients recognized by Chef Sprout',
                              style: SproutTypography.small(
                                color: SproutColors.primaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: SproutColors.sproutGreen,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Scrollable Chips Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No ingredients selected. Tap Add Item below.',
                            style: SproutTypography.body(color: SproutColors.muted),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _ingredients.map((item) {
                          final isSelected = _selectedItems.contains(item);
                          final displayName = item.isNotEmpty
                              ? item[0].toUpperCase() + item.substring(1)
                              : item;

                          return SproutBouncyTap(
                            onTap: () => _toggleItem(item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SproutColors.sproutGreen.withValues(alpha: 0.12)
                                    : SproutColors.canvas,
                                borderRadius: SproutRadii.borderPill,
                                border: Border.all(
                                  color: isSelected
                                      ? SproutColors.sproutGreen
                                      : SproutColors.sage.withValues(alpha: 0.35),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 17,
                                    color: isSelected
                                        ? SproutColors.sproutGreen
                                        : SproutColors.muted,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    displayName,
                                    style: SproutTypography.body(
                                      color: isSelected
                                          ? SproutColors.primaryInk
                                          : SproutColors.secondaryInk,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeItem(item),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? SproutColors.sproutGreen
                                          : SproutColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Inline Add Custom Item Input
                    if (_isAddingCustom) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Enter ingredient name...',
                                hintStyle: SproutTypography.small(color: SproutColors.muted),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                filled: true,
                                fillColor: SproutColors.canvas,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: SproutColors.sage.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _addCustomItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: SproutColors.sproutGreen),
                            onPressed: _addCustomItem,
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel_rounded, color: SproutColors.muted),
                            onPressed: () {
                              setState(() {
                                _isAddingCustom = false;
                                _addController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add missing item'),
                        style: TextButton.styleFrom(
                          foregroundColor: SproutColors.sproutGreen,
                          textStyle: SproutTypography.smallBold(),
                        ),
                        onPressed: () => setState(() => _isAddingCustom = true),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Confirm / Add to Kitchen Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SproutButton(
                label: _selectedItems.isEmpty
                    ? 'Select at least 1 item'
                    : 'Add ${_selectedItems.length} ${_selectedItems.length == 1 ? "Item" : "Items"} to Kitchen 🍳',
                onPressed: _selectedItems.isEmpty
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        widget.onConfirm(_selectedItems.toList());
                      },
                height: 52,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
