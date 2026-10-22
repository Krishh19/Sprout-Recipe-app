import 'package:flutter/material.dart';

import '../colors.dart';
import '../motion.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';

enum SproutButtonVariant { primary, secondary, ghost, destructive }

class SproutButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final SproutButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double height;
  final double? width;

  const SproutButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SproutButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
  });

  @override
  State<SproutButton> createState() => _SproutButtonState();
}

class _SproutButtonState extends State<SproutButton> {
  bool _isPressed = false;

  bool get _isInteractive => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool pressed) {
    if (!_isInteractive || pressed == _isPressed) return;
    if (pressed) {
      SproutHaptics.light();
    }
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        SproutColors.isDarkMode;

    switch (widget.variant) {
      case SproutButtonVariant.primary:
        bg = isDark ? const Color(0xFF254B36) : SproutColors.forestGreen;
        fg = Colors.white;
        break;
      case SproutButtonVariant.secondary:
        bg = isDark
            ? SproutColors.nightElevatedSurface
            : SproutColors.softIvory;
        fg = isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary;
        border = Border.all(
          color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
          width: 1.2,
        );
        break;
      case SproutButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? SproutColors.nightAccent : SproutColors.forestGreen;
        break;
      case SproutButtonVariant.destructive:
        bg = SproutColors.error;
        fg = Colors.white;
        break;
    }

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: SproutMotion.fast,
          curve: SproutMotion.emphasized,
          child: AnimatedContainer(
            duration: SproutMotion.fast,
            height: widget.height,
            width: widget.width,
            decoration: ShapeDecoration(
              color: widget.onPressed == null ? bg.withValues(alpha: 0.5) : bg,
              shape: SproutRadii.squircleButton(
                side: border != null ? border.top : BorderSide.none,
              ),
              shadows:
                  widget.variant == SproutButtonVariant.primary &&
                      widget.onPressed != null
                  ? [
                      BoxShadow(
                        color:
                            (isDark
                                    ? SproutColors.nightAccent
                                    : SproutColors.forestGreen)
                                .withValues(alpha: isDark ? 0.28 : 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isInteractive ? widget.onPressed : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(fg),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SproutTypography.button(color: fg),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
