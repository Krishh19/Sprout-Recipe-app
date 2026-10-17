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
    this.height = 54.0,
    this.width,
  });

  @override
  State<SproutButton> createState() => _SproutButtonState();
}

class _SproutButtonState extends State<SproutButton> {
  bool _isPressed = false;

  bool get _isInteractive =>
      widget.onPressed != null && !widget.isLoading;

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

    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;

    switch (widget.variant) {
      case SproutButtonVariant.primary:
        bg = isDark ? const Color(0xFF2E6349) : SproutColors.sproutGreen;
        fg = Colors.white;
        break;
      case SproutButtonVariant.secondary:
        bg = SproutColors.surface;
        fg = SproutColors.primaryInk;
        border = Border.all(color: SproutColors.sage.withValues(alpha: 0.3), width: 1.2);
        break;
      case SproutButtonVariant.ghost:
        bg = Colors.transparent;
        fg = SproutColors.primaryInk;
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
              shadows: widget.variant == SproutButtonVariant.primary &&
                      widget.onPressed != null
                  ? [
                      BoxShadow(
                        color: SproutColors.sproutGreen.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: SproutRadii.squircleButton(),
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: Row(
                    mainAxisSize: widget.width == null
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SproutTypography.body(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
