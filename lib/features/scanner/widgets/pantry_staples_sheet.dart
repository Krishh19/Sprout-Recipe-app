import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_button.dart';
import '../../../design/radii.dart';
import '../../../design/typography.dart';
import '../../../providers/app_providers.dart';

class PantryStaplesSheet extends ConsumerStatefulWidget {
  const PantryStaplesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PantryStaplesSheet(),
    );
  }

  @override
  ConsumerState<PantryStaplesSheet> createState() => _PantryStaplesSheetState();
}

class _PantryStaplesSheetState extends ConsumerState<PantryStaplesSheet> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustomStaple() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(pantryStaplesProvider.notifier).addStaple(text);
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final staplesState = ref.watch(pantryStaplesProvider).value ??
        const PantryStaplesState();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SproutColors.sage.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Kitchen Staples', style: SproutTypography.h3()),
                          const SizedBox(width: 6),
                          const Text('🧂', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pantry essentials you always have at home',
                        style: SproutTypography.caption(
                          color: SproutColors.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Master Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: staplesState.isEnabled
                    ? SproutColors.sproutGreen.withValues(alpha: 0.08)
                    : SproutColors.sage.withValues(alpha: 0.12),
                borderRadius: SproutRadii.card,
                border: Border.all(
                  color: staplesState.isEnabled
                      ? SproutColors.sproutGreen.withValues(alpha: 0.25)
                      : SproutColors.sage.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    staplesState.isEnabled
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_outlined,
                    color: staplesState.isEnabled
                        ? SproutColors.sproutGreen
                        : SproutColors.secondaryInk,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Include in recipe matching',
                          style: SproutTypography.bodyBold().copyWith(fontSize: 14),
                        ),
                        Text(
                          'Counts active staples towards 100% matches',
                          style: SproutTypography.caption(
                            color: SproutColors.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: staplesState.isEnabled,
                    activeTrackColor: SproutColors.sproutGreen,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(pantryStaplesProvider.notifier).toggleEnabled();
                    },
                  ),

                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Staples (${staplesState.staples.length})',
                  style: SproutTypography.smallBold(
                    color: SproutColors.secondaryInk,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(pantryStaplesProvider.notifier).resetToDefaults();
                  },
                  child: Text(
                    'Reset Defaults',
                    style: SproutTypography.caption(
                      color: SproutColors.sproutGreen,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scrollable Staples Chips
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: staplesState.staples.map((staple) {
                        return FilterChip(
                          label: Text(
                            staple[0].toUpperCase() + staple.substring(1),
                            style: SproutTypography.body(
                              color: SproutColors.primaryInk,
                            ).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          selected: true,
                          showCheckmark: true,
                          selectedColor:
                              SproutColors.sproutGreen.withValues(alpha: 0.15),
                          checkmarkColor: SproutColors.sproutGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: SproutRadii.borderPill,
                            side: const BorderSide(
                              color: SproutColors.sproutGreen,
                              width: 1.2,
                            ),
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(pantryStaplesProvider.notifier)
                                .toggleStaple(staple);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Add custom staple input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addCustomStaple(),
                            decoration: InputDecoration(
                              hintText: 'Add staple (e.g. soy sauce, ghee)...',
                              hintStyle: SproutTypography.body(
                                color: SproutColors.secondaryInk.withValues(alpha: 0.6),
                              ).copyWith(fontSize: 13),
                              filled: true,
                              fillColor: SproutColors.canvas,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: SproutColors.sage.withValues(alpha: 0.25),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: SproutColors.sage.withValues(alpha: 0.25),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: SproutColors.sproutGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SproutButton(
                          label: 'Add',
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          height: 48,
                          onPressed: _addCustomStaple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Done Button
            SproutButton(
              label: 'Done',
              width: double.infinity,
              onPressed: () => Navigator.of(context).pop(),
            ),

          ],
        ),
      ),
    );
  }
}
