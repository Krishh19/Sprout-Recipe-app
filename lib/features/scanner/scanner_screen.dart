import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_button.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_filter_chip.dart';
import '../../design/components/sprout_recipe_row.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_shimmer.dart';
import '../../design/radii.dart';
import '../../design/spacing.dart';
import '../../design/sprout_haptics.dart';
import '../../design/typography.dart';
import '../../providers/app_providers.dart';
import '../recipes/recipe_detail_screen.dart';
import 'widgets/ingredient_list_card.dart';
import 'widgets/pantry_staples_sheet.dart';
import 'widgets/quick_add_section.dart';
import 'widgets/scanned_ingredients_sheet.dart';
import 'widgets/scanner_checklist_card.dart';
import 'widgets/scanner_hero_header.dart';
import 'widgets/scanner_pro_tip_card.dart';
import 'widgets/scanner_top_bar.dart';
import 'widgets/scanner_viewfinder.dart';
import 'widgets/barcode_scanner_view.dart';

enum ScannerMode { vision, barcode }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _manualInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ScannerMode _mode = ScannerMode.vision;
  bool _isAnalyzing = false;
  Uint8List? _capturedBytes;
  int _analysisStep = 1; // 1 to 3
  bool _isCancelled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _cancelScan() {
    _isCancelled = true;
    setState(() {
      _isAnalyzing = false;
      _capturedBytes = null;
      _analysisStep = 1;
    });
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();
      if (!mounted) return;

      setState(() {
        _isCancelled = false;
        _isAnalyzing = true;
        _capturedBytes = bytes;
        _analysisStep = 1;
      });

      // Ensure analysis layout is anchored at the top of viewport
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }

      // Execute Gemini vision analysis
      final detected = await ref
          .read(scannerRepositoryProvider)
          .analyzeImageWithGemini(bytes);

      if (_isCancelled || !mounted) return;

      if (detected.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _capturedBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No ingredients recognized. Try taking a closer, well-lit photo.',
            ),
          ),
        );
        return;
      }

      // Step 2: Preparing review
      SproutHaptics.medium();
      setState(() {
        _analysisStep = 2;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (_isCancelled || !mounted) return;

      // Finish analysis state before opening immersive sheet
      setState(() {
        _isAnalyzing = false;
      });

      // Show immersive ScannedIngredientsSheet for interactive review & confirmation
      if (mounted) {
        await ScannedIngredientsSheet.show(
          context,
          detectedIngredients: detected,
          capturedImageBytes: _capturedBytes,
          onConfirm: (confirmedIngredients) {
            SproutHaptics.success();
            final current = ref.read(scannerProvider).detectedIngredients;
            final merged = {...current, ...confirmedIngredients}.toList();
            ref.read(scannerProvider.notifier).setIngredients(merged);
            ref.read(scannerProvider.notifier).findMatches();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${confirmedIngredients.length} ingredients to your kitchen! 🌱',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1800),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                backgroundColor: SproutColors.sproutGreen,
              ),
            );

            // Animate scroll to reveal ingredients
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                260.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _capturedBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete scan: $e')),
      );
    }
  }

  void _showAddManualIngredientSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Ingredient', style: SproutTypography.h3()),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualInputController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Tomato, Paneer, Cumin...',
                hintStyle: SproutTypography.body(color: SproutColors.muted),
                filled: true,
                fillColor: SproutColors.canvas,
                border: OutlineInputBorder(
                  borderRadius: SproutRadii.borderMd,
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  ref.read(scannerProvider.notifier).addIngredient(val.trim());
                  _manualInputController.clear();
                  Navigator.of(ctx).pop();
                  ref.read(scannerProvider.notifier).findMatches();
                }
              },
            ),
            const SizedBox(height: 16),
            SproutButton(
              label: 'Add to List',
              width: double.infinity,
              onPressed: () {
                final val = _manualInputController.text.trim();
                if (val.isNotEmpty) {
                  ref.read(scannerProvider.notifier).addIngredient(val);
                  _manualInputController.clear();
                  Navigator.of(ctx).pop();
                  ref.read(scannerProvider.notifier).findMatches();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);
    SproutColors.setDarkMode(isDark);
    final scannerState = ref.watch(scannerProvider);

    return SproutScaffold(
      body: SafeArea(
        bottom: false, // let content scroll beneath the glass nav bar
        child: CustomScrollView(
          controller: _scrollController,
          physics: _isAnalyzing
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          slivers: [
            // 1. Top Bar with Sprout Wordmark and How it works / Cancel
            SliverToBoxAdapter(
              child: ScannerTopBar(
                isAnalyzing: _isAnalyzing,
                onCancel: _cancelScan,
              ),
            ),

            // 2. Hero Header with Kalam typography & Mascot
            SliverToBoxAdapter(
              child: ScannerHeroHeader(
                isAnalyzing: _isAnalyzing,
              ),
            ),

            // Mode Selector Pill (AI Vision vs Barcode)
            if (!_isAnalyzing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? SproutColors.nightElevatedSurface
                          : SproutColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.camera_alt_rounded,
                            label: 'AI Vision',
                            isSelected: _mode == ScannerMode.vision,
                            onTap: () => setState(() => _mode = ScannerMode.vision),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Barcode',
                            isSelected: _mode == ScannerMode.barcode,
                            onTap: () => setState(() => _mode = ScannerMode.barcode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Viewfinder Hero Card
            if (_mode == ScannerMode.barcode)
              const SliverToBoxAdapter(
                child: BarcodeScannerView(),
              )
            else ...[
              SliverToBoxAdapter(
                child: ScannerViewfinder(
                  isAnalyzing: _isAnalyzing,
                  capturedImageBytes: _capturedBytes,
                ),
              ),

              if (!_isAnalyzing) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // Camera Action Button
                      Expanded(
                        child: SproutBouncyTap(
                          onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: SproutColors.sproutGreen,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: SproutColors.sproutGreen.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Camera',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SproutTypography.bodyBold(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Upload Action Button
                      Expanded(
                        child: SproutBouncyTap(
                          onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: SproutColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : SproutColors.sage.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  color: SproutColors.primaryInk,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Upload Photo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SproutTypography.bodyBold(color: SproutColors.primaryInk),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // 4. Analyzing State Components: 3-Step Checklist Card & Pro Tip Card
            if (_isAnalyzing) ...[
              SliverToBoxAdapter(
                child: ScannerChecklistCard(
                  currentStep: _analysisStep,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(
                child: ScannerProTipCard(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ]

            // 5. Idle / Ready State Components: Quick Add & Ingredients List
            else ...[
              SliverToBoxAdapter(
                child: QuickAddSection(
                  onSelectPreset: (presetIngredients) {
                    ref
                        .read(scannerProvider.notifier)
                        .setIngredients(presetIngredients);
                    ref.read(scannerProvider.notifier).findMatches();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: IngredientListCard(
                  ingredients: scannerState.detectedIngredients,
                  onRemoveIngredient: (item) {
                    ref.read(scannerProvider.notifier).removeIngredient(item);
                    ref.read(scannerProvider.notifier).findMatches();
                  },
                  onAddTap: _showAddManualIngredientSheet,
                  onClearAll: () {
                    ref.read(scannerProvider.notifier).clearIngredients();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Matching Recipes Section (Only shown when ingredients are present)
              if (scannerState.detectedIngredients.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Matching Recipes (${scannerState.matchedRecipes.length})',
                            overflow: TextOverflow.ellipsis,
                            style: SproutTypography.h3(),
                          ),
                        ),
                        if (scannerState.isMatching)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SproutColors.sproutGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Filter Bar: 100% Match Only & Kitchen Staples Manager
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SproutFilterChip(
                            label: 'Zero Missing (100% Match)',
                            emoji: scannerState.only100PercentMatch ? '✅' : null,
                            isSelected: scannerState.only100PercentMatch,

                            onSelected: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(scannerProvider.notifier)
                                  .toggle100PercentMatch();
                            },
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final staplesState =
                                  ref.watch(pantryStaplesProvider).value;
                              final count = staplesState?.staples.length ?? 0;
                              final isEnabled =
                                  staplesState?.isEnabled ?? true;
                              return ActionChip(
                                avatar: const Text(
                                  '🧂',
                                  style: TextStyle(fontSize: 14),
                                ),
                                label: Text(
                                  isEnabled
                                      ? 'Staples ($count)'
                                      : 'Staples (Off)',
                                  style: SproutTypography.caption(
                                    color: isEnabled
                                        ? SproutColors.primaryInk
                                        : SproutColors.secondaryInk,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: isEnabled
                                    ? SproutColors.sproutGreen
                                        .withValues(alpha: 0.12)
                                    : SproutColors.surface,
                                side: BorderSide(
                                  color: isEnabled
                                      ? SproutColors.sproutGreen
                                          .withValues(alpha: 0.35)
                                      : SproutColors.sage.withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: SproutRadii.borderPill,
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  PantryStaplesSheet.show(context);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Matching Recipes List

                if (scannerState.isMatching)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const SproutRecipeRowSkeleton(),
                        childCount: 3,
                      ),
                    ),
                  )
                else if (scannerState.matchedRecipes.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 48.0),
                      child: SproutEmptyState(
                        title: 'No recipes found',
                        subtitle:
                            'Try adding more ingredients like onion, tomato, or garlic.',
                        actionLabel: 'Add More Ingredients',
                        onAction: _showAddManualIngredientSheet,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recipe = scannerState.matchedRecipes[index];
                          return SproutRecipeRow(
                            recipe: recipe,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            },
                            onFavoriteToggle: () {
                              ref
                                  .read(savedRecipesProvider.notifier)
                                  .toggleFavorite(recipe);
                            },
                          );
                        },
                        childCount: scannerState.matchedRecipes.length,
                      ),
                    ),
                  ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                    child: Center(
                      child: Text(
                        'Scan your groceries or add ingredients above\nto see smart recipe matches.',
                        textAlign: TextAlign.center,
                        style: SproutTypography.body(
                          color: SproutColors.muted,
                        ).copyWith(height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],

              SliverToBoxAdapter(
                child: SizedBox(
                  height: SproutSpacing.navClearance +
                      MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    return GestureDetector(
      onTap: () {
        SproutHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SproutColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? SproutColors.nightAccent : SproutColors.sproutGreen)
                  : SproutColors.secondaryInk,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SproutTypography.caption(
                  color: isSelected ? SproutColors.primaryInk : SproutColors.secondaryInk,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
