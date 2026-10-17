import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_assets.dart';
import '../../../design/typography.dart';

enum StepStatus { completed, active, pending }

class ScannerChecklistCard extends StatelessWidget {
  final int currentStep; // 1 to 3

  const ScannerChecklistCard({
    super.key,
    this.currentStep = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.primaryInk.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChecklistItem(
            status: currentStep > 1
                ? StepStatus.completed
                : (currentStep == 1 ? StepStatus.active : StepStatus.pending),
            title: 'Finding ingredients',
            subtitle: 'Detecting items in your photo...',
            iconAsset: SproutAssets.checklistLeaves,
            isLast: false,
          ),
          _buildChecklistItem(
            status: currentStep > 2
                ? StepStatus.completed
                : (currentStep == 2 ? StepStatus.active : StepStatus.pending),
            title: 'Matching ingredients',
            subtitle: 'Pairing with delicious recipes...',
            iconAsset: SproutAssets.checklistMushroom,
            isLast: false,
          ),
          _buildChecklistItem(
            status: currentStep > 3
                ? StepStatus.completed
                : (currentStep == 3 ? StepStatus.active : StepStatus.pending),
            title: 'Finding recipes',
            subtitle: 'Preparing your recommendations...',
            iconAsset: SproutAssets.checklistRecipeBook,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required StepStatus status,
    required String title,
    required String subtitle,
    required String iconAsset,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator + Dotted Connector
          Column(
            children: [
              _buildIndicator(status),
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    size: const Size(2, 22),
                    painter: _DottedLinePainter(
                      color: SproutColors.sage.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Titles & Descriptions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SproutTypography.body(
                      fontWeight: status == StepStatus.active
                          ? FontWeight.w700
                          : (status == StepStatus.completed
                              ? FontWeight.w600
                              : FontWeight.w500),
                      color: status == StepStatus.pending
                          ? SproutColors.muted
                          : SproutColors.primaryInk,
                    ).copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: SproutTypography.small(
                      color: status == StepStatus.pending
                          ? SproutColors.muted.withValues(alpha: 0.7)
                          : SproutColors.secondaryInk,
                    ).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Right Styling Icon Asset
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(StepStatus status) {
    switch (status) {
      case StepStatus.completed:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF2E653A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Colors.white,
          ),
        );
      case StepStatus.active:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2E653A),
              width: 2.0,
            ),
            color: Colors.white,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2E653A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case StepStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: SproutColors.muted.withValues(alpha: 0.4),
              width: 1.6,
            ),
            color: Colors.white,
          ),
        );
    }
  }
}

/// CustomPainter that renders a clean vertical dotted line
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 2.0;

    while (startY < size.height - 2.0) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
