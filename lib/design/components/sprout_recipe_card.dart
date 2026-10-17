import 'package:flutter/material.dart';
import '../../models/recipe.dart';

import '../colors.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';
import 'sprout_diet_badge.dart';
import 'sprout_recipe_image.dart';

class SproutRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final double imageHeight;

  /// Namespaces the shared-element Hero tag so the same recipe can
  /// appear in multiple sections without tag collisions.
  final String heroTagPrefix;

  const SproutRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteToggle,
    this.width = 240.0,
    this.imageHeight = 160.0,
    this.heroTagPrefix = 'recipe_image',
  });

  @override
  State<SproutRecipeCard> createState() => _SproutRecipeCardState();
}

class _SproutRecipeCardState extends State<SproutRecipeCard>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  late AnimationController _burstController;
  late Animation<double> _burstScale;
  late Animation<double> _burstOpacity;
  bool _showBurstHeart = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(_heartController);

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _burstScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_burstController);

    _burstOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_burstController);

    _burstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showBurstHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _handleFavorite() {
    SproutHaptics.light();
    _heartController.forward(from: 0.0);
    widget.onFavoriteToggle?.call();
  }

  void _triggerDoubleTapHeart() {
    SproutHaptics.medium();
    setState(() => _showBurstHeart = true);
    _burstController.forward(from: 0.0);
    _heartController.forward(from: 0.0);
    if (!widget.recipe.isSaved) {
      widget.onFavoriteToggle?.call();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label:
          'Recipe: ${widget.recipe.title}, ${widget.recipe.cuisine}, '
          '${widget.recipe.totalTimeMins > 0 ? '${widget.recipe.totalTimeMins} minutes' : 'quick meal'}',
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: SproutColors.surface,
          borderRadius: SproutRadii.card,
          border: Border.all(
            color: SproutColors.sage.withValues(alpha: 0.22),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: SproutColors.primaryInk.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: SproutRadii.card,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: SproutRadii.card,
              onTap: widget.onTap,
              onDoubleTap: _triggerDoubleTapHeart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
            children: [
              // Image container with heart overlay
              Stack(
                children: [
                  Hero(
                    tag: '${widget.heroTagPrefix}_${widget.recipe.id}',
                    flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final radius = flightDirection == HeroFlightDirection.push
                              ? (1.0 - animation.value) * 23.0
                              : animation.value * 23.0;
                          return ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                            child: toHeroContext.widget,
                          );
                        },
                      );
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(23.0),
                      ),
                      child: SizedBox(
                        height: widget.imageHeight,
                        width: double.infinity,
                        child: _buildCardImage(),
                      ),
                    ),
                  ),

                  // Center Bursting Heart Animation on Double Tap
                  if (_showBurstHeart)
                    Positioned.fill(
                      child: Center(
                        child: FadeTransition(
                          opacity: _burstOpacity,
                          child: ScaleTransition(
                            scale: _burstScale,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: SproutColors.tomato
                                        .withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: SproutColors.tomato,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Favorite Button

                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _handleFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        button: true,
                        toggled: widget.recipe.isSaved,
                        label: widget.recipe.isSaved
                            ? 'Remove ${widget.recipe.title} from saved recipes'
                            : 'Save ${widget.recipe.title}',
                        child: ScaleTransition(
                          scale: _heartScale,
                          child: Container(
                            // 48dp minimum touch target (icon + padding + margin)
                            margin: const EdgeInsets.all(6.0),
                            padding: const EdgeInsets.all(9.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.recipe.isSaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: widget.recipe.isSaved
                                  ? SproutColors.tomato
                                  : SproutColors.primaryInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Match percentage pill if present
                  if (widget.recipe.matchPercentage > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SproutColors.sproutGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${widget.recipe.matchPercentage.toInt()}% match',
                          style: SproutTypography.caption(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Recipe Metadata & Title
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SproutTypography.h3().copyWith(
                        fontSize: 17,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SproutDietBadge(diet: widget.recipe.diet, size: 12),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: SproutColors.secondaryInk,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.recipe.totalTimeMins > 0
                              ? '${widget.recipe.totalTimeMins}m'
                              : '25m',
                          style: SproutTypography.small(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '·',
                          style: SproutTypography.smallBold(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.recipe.cuisine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SproutTypography.small(),
                          ),
                        ),
                        if (widget.recipe.rating != null) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                          const SizedBox(width: 1),
                          Text(
                            widget.recipe.rating!.toStringAsFixed(1),
                            style: SproutTypography.smallBold(),
                          ),
                        ],
                      ],
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
);
}

  Widget _buildCardImage() {
    return SproutRecipeImage(
      imageUrl: widget.recipe.imageUrl,
      cuisine: widget.recipe.cuisine,
      title: widget.recipe.title,
      height: widget.imageHeight,
      width: double.infinity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(23.0)),
    );
  }
}
