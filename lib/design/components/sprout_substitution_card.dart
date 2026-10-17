import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../colors.dart';
import '../radii.dart';
import '../typography.dart';
import '../../models/substitution_model.dart';
import '../../providers/app_providers.dart';
import 'sprout_bouncy_tap.dart';

class SproutSubstitutionCard extends ConsumerStatefulWidget {
  final List<String> missingIngredients;
  final String recipeTitle;

  const SproutSubstitutionCard({
    super.key,
    required this.missingIngredients,
    required this.recipeTitle,
  });

  @override
  ConsumerState<SproutSubstitutionCard> createState() => _SproutSubstitutionCardState();
}

class _SproutSubstitutionCardState extends ConsumerState<SproutSubstitutionCard> {
  bool _isLoading = false;
  List<SubstitutionModel>? _substitutions;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchSubstitutions();
  }

  Future<void> _fetchSubstitutions() async {
    if (widget.missingIngredients.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(substitutionServiceProvider);
      final results = await service.getSubstitutions(
        missingIngredients: widget.missingIngredients,
        recipeTitle: widget.recipeTitle,
      );
      if (mounted) {
        setState(() {
          _substitutions = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.missingIngredients.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: SproutColors.sproutGreen.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.sproutGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          SproutBouncyTap(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: SproutColors.sproutGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pantry Substitutions',
                          style: SproutTypography.bodyBold(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.missingIngredients.length} missing items can be swapped',
                          style: SproutTypography.small(color: SproutColors.secondaryInk),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: SproutColors.muted,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0x1F8DA399)),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(SproutColors.sproutGreen),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Consulting Chef Sprout for culinary swaps...'),
                    ],
                  ),
                ),
              )
            else if (_substitutions != null && _substitutions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: _substitutions!.map((sub) => _buildSubItem(sub)).toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: SproutColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Missing items: ${widget.missingIngredients.join(", ")}',
                        style: SproutTypography.small(color: SproutColors.secondaryInk),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchSubstitutions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubItem(SubstitutionModel sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: SproutColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Missing chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SproutColors.tomato.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No ${sub.originalIngredient}',
                  style: SproutTypography.caption(
                    color: SproutColors.tomato,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: SproutColors.muted,
              ),
              // Substitute chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SproutColors.sproutGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sub.substitute,
                  style: SproutTypography.caption(
                    color: SproutColors.sproutGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Culinary tip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0, right: 6.0),
                child: Icon(Icons.lightbulb_outline_rounded, size: 14, color: SproutColors.sproutGreen),
              ),
              Expanded(
                child: Text(
                  sub.culinaryTip,
                  style: SproutTypography.small(color: SproutColors.primaryInk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
