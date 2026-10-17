import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../design/colors.dart';
import '../../../design/components/sprout_button.dart';
import '../../../design/components/sprout_diet_badge.dart';
import '../../../design/components/sprout_recipe_image.dart';
import '../../../design/typography.dart';
import '../../../models/recipe.dart';


class RecipeShareCardSheet extends StatefulWidget {
  final Recipe recipe;

  const RecipeShareCardSheet({super.key, required this.recipe});

  static Future<void> show(BuildContext context, {required Recipe recipe}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeShareCardSheet(recipe: recipe),
    );
  }

  @override
  State<RecipeShareCardSheet> createState() => _RecipeShareCardSheetState();
}

class _RecipeShareCardSheetState extends State<RecipeShareCardSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  String _buildShareText() {
    final r = widget.recipe;
    final buffer = StringBuffer();
    buffer.writeln('🌱 Cooking with Sprout: ${r.title}');
    buffer.writeln('⏱️ ${r.totalTimeMins} mins · 🍽️ ${r.cuisine} · ${r.diet.toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('Key Ingredients:');
    for (final ing in r.ingredients.take(6)) {
      buffer.writeln('• $ing');
    }
    buffer.writeln('');
    buffer.writeln('Cook smart with what\'s in your fridge using Sprout! 🍳');
    return buffer.toString();
  }

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/sprout_${widget.recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);

          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path)],
            text: _buildShareText(),
          );
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error sharing card image: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }

    // Graceful fallback to text share if image capture wasn't available
    // ignore: deprecated_member_use
    await Share.share(_buildShareText());
    if (mounted) Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SproutColors.sage.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Share Recipe Card ✨', style: SproutTypography.h3()),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Preview (Anchored inside RepaintBoundary)
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SproutColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: SproutColors.sproutGreen.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SproutColors.primaryInk.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Image Banner
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: SproutRecipeImage(
                              imageUrl: r.imageUrl,
                              cuisine: r.cuisine,
                              height: 160,
                              width: double.infinity,
                              isDetail: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title & Cuisine
                        Text(
                          r.title,
                          style: SproutTypography.h3().copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SproutDietBadge(diet: r.diet),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SproutColors.sage.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.cuisine,
                                style: SproutTypography.caption(
                                  color: SproutColors.secondaryInk,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: SproutColors.secondaryInk,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${r.totalTimeMins} mins',
                              style: SproutTypography.caption(
                                color: SproutColors.secondaryInk,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Key Ingredients Preview
                        Text(
                          'Ingredients:',
                          style: SproutTypography.smallBold(
                            color: SproutColors.secondaryInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...r.ingredients.take(4).map(
                              (ing) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: SproutColors.sproutGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ing,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: SproutTypography.caption(
                                          color: SproutColors.primaryInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (r.ingredients.length > 4)
                          Text(
                            '+ ${r.ingredients.length - 4} more ingredients',
                            style: SproutTypography.caption(
                              color: SproutColors.secondaryInk,
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        const SizedBox(height: 16),

                        // Sprout Branding Footer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: SproutColors.sproutGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('🌱', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sprout · Smart AI Kitchen',
                                    style: SproutTypography.caption(
                                      color: SproutColors.sproutGreen,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Text(
                                'sprout.app',
                                style: SproutTypography.caption(
                                  color: SproutColors.secondaryInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Share CTA Button
            SproutButton(
              label: _isSharing ? 'Generating Card...' : 'Share Recipe Card 🚀',
              icon: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 18,
              ),
              width: double.infinity,
              isLoading: _isSharing,
              onPressed: _isSharing ? null : _shareCard,
            ),

          ],
        ),
      ),
    );
  }
}
