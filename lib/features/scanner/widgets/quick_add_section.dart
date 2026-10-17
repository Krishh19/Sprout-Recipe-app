import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_bouncy_tap.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

class QuickAddSection extends StatefulWidget {
  final ValueChanged<List<String>> onSelectPreset;

  const QuickAddSection({
    super.key,
    required this.onSelectPreset,
  });

  @override
  State<QuickAddSection> createState() => _QuickAddSectionState();
}

class _QuickAddSectionState extends State<QuickAddSection> {
  final ScrollController _scrollController = ScrollController();

  final List<_PresetItem> _presets = const [
    _PresetItem(
      label: 'Fresh Produce',
      iconAsset: 'assets/ingredients/tomato.png',
      ingredients: ['tomato', 'onion', 'garlic', 'spinach', 'carrot'],
    ),
    _PresetItem(
      label: 'Pantry Items',
      iconAsset: 'assets/ingredients/potato.png',
      ingredients: ['potato', 'pulses', 'rice', 'jeera', 'turmeric'],
    ),
    _PresetItem(
      label: 'Dairy',
      iconAsset: 'assets/ingredients/cream.png',
      ingredients: ['paneer', 'cheese', 'butter', 'cream'],
    ),
    _PresetItem(
      label: 'Herbs & Spices',
      iconAsset: 'assets/ingredients/coriander.png',
      ingredients: ['coriander', 'ginger', 'green chillies', 'mint'],
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollNext() {
    if (_scrollController.hasClients) {
      final current = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;
      final target = current + 130.0 > max ? 0.0 : current + 130.0;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with Spark Accent
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Or try a quick add',
                style: SproutTypography.h3(color: SproutColors.primaryInk).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                SproutAssets.strokeSparkBurst,
                width: 22,
                height: 12,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(' ✨'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Horizontal List of Category Pills
        SizedBox(
          height: 38,
          child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              ..._presets.map((preset) => _buildPresetPill(preset)),
              // Next / Cycle Arrow Button
              SproutBouncyTap(
                onTap: _scrollNext,
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: SproutColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SproutColors.sage.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SproutColors.primaryInk.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: SproutColors.primaryInk,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetPill(_PresetItem preset) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: SproutBouncyTap(
        onTap: () => widget.onSelectPreset(preset.ingredients),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SproutColors.surface,
            borderRadius: SproutRadii.borderPill,
            border: Border.all(
              color: SproutColors.sage.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: SproutColors.primaryInk.withValues(alpha: 0.03),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                preset.iconAsset,
                width: 19,
                height: 19,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.local_florist_rounded,
                  size: 15,
                  color: SproutColors.sproutGreen,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                preset.label,
                style: SproutTypography.smallBold(
                  color: SproutColors.primaryInk,
                ).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetItem {
  final String label;
  final String iconAsset;
  final List<String> ingredients;

  const _PresetItem({
    required this.label,
    required this.iconAsset,
    required this.ingredients,
  });
}
