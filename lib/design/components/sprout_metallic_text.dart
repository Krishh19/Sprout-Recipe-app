import 'package:flutter/material.dart';
import '../colors.dart';

/// Renders main heading text with a lustrous golden metallic gradient in dark mode,
/// and artisanal primary ink in light mode (or forced metallic if desired).
class SproutMetallicHeading extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool forceMetallic;

  const SproutMetallicHeading(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.forceMetallic = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    if (!isDark && !forceMetallic) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final rect = bounds.isEmpty ? const Rect.fromLTWH(0, 0, 240, 50) : bounds;
        return SproutColors.goldGradient.createShader(rect);
      },
      child: Text(
        text,
        style: style.copyWith(
          color: Colors.white,
          shadows: isDark
              ? [
                  Shadow(
                    color: const Color(0xFFC4861C).withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
