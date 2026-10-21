import 'package:flutter/material.dart';
import '../colors.dart';
import '../radii.dart';
import '../sprout_haptics.dart';
import '../typography.dart';
import 'sprout_typewriter_hint.dart';

class SproutSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final String hintText;
  final List<String>? animatedHints;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool enableVoiceSearch;
  final bool isListeningVoice;
  final VoidCallback? onVoiceSearchTap;

  const SproutSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onClear,
    this.hintText = 'Search recipes, ingredients...',
    this.animatedHints,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.enableVoiceSearch = false,
    this.isListeningVoice = false,
    this.onVoiceSearchTap,
  });

  @override
  State<SproutSearchBar> createState() => _SproutSearchBarState();
}

class _SproutSearchBarState extends State<SproutSearchBar>
    with SingleTickerProviderStateMixin {
  late FocusNode _internalFocusNode;
  late TextEditingController _internalController;
  late AnimationController _pulseController;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;

  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _internalController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isListeningVoice) {
      _pulseController.repeat(reverse: true);
    }

    _effectiveFocusNode.addListener(_handleFocusChange);
    _effectiveController.addListener(_handleTextChange);
    _hasFocus = _effectiveFocusNode.hasFocus;
    _hasText = _effectiveController.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant SproutSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      _effectiveController.addListener(_handleTextChange);
    }
    if (widget.isListeningVoice != oldWidget.isListeningVoice) {
      if (widget.isListeningVoice) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _effectiveController.removeListener(_handleTextChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    final nowHasText = _effectiveController.text.isNotEmpty;
    if (nowHasText != _hasText && mounted) {
      setState(() {
        _hasText = nowHasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final showTypewriter = (widget.animatedHints != null &&
        widget.animatedHints!.isNotEmpty &&
        !_hasFocus &&
        !_hasText);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? SproutColors.nightSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: SproutRadii.borderPill,
        border: Border.all(
          color: widget.isListeningVoice
              ? (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : SproutColors.subtleBorder.withValues(alpha: 0.9)),
          width: widget.isListeningVoice ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isListeningVoice
                ? (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
                    .withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: widget.isListeningVoice ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Underlying TextField
          TextField(
            controller: _effectiveController,
            focusNode: _effectiveFocusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            style: SproutTypography.body(
              color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
            ),
            cursorColor: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
            decoration: InputDecoration(
              hintText: showTypewriter ? null : widget.hintText,
              hintStyle: SproutTypography.body(
                color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
              ).copyWith(fontSize: 15),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clear button when text is present
                  if (_hasText)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
                      tooltip: 'Clear search',
                      onPressed: () {
                        _effectiveController.clear();
                        widget.onClear?.call();
                        widget.onChanged?.call('');
                      },
                    ),

                  // Voice Search button
                  if (widget.enableVoiceSearch || widget.onVoiceSearchTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseScale = widget.isListeningVoice
                              ? 1.0 + (_pulseController.value * 0.18)
                              : 1.0;
                          return Transform.scale(
                            scale: pulseScale,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  SproutHaptics.selection();
                                  widget.onVoiceSearchTap?.call();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: widget.isListeningVoice
                                        ? (isDark
                                            ? SproutColors.nightAccent.withValues(alpha: 0.25)
                                            : SproutColors.paleSage.withValues(alpha: 0.95))
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: widget.isListeningVoice
                                        ? Border.all(
                                            color: isDark
                                                ? SproutColors.nightAccent
                                                : SproutColors.forestGreen,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    widget.isListeningVoice
                                        ? Icons.mic_rounded
                                        : Icons.mic_none_rounded,
                                    size: 20,
                                    color: widget.isListeningVoice
                                        ? (isDark ? SproutColors.nightAccent : SproutColors.forestGreen)
                                        : (isDark
                                            ? SproutColors.nightSecondaryInk
                                            : SproutColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Filter / Tune button
                  if (widget.onFilterTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            SproutHaptics.light();
                            widget.onFilterTap?.call();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? SproutColors.nightElevatedSurface
                                  : SproutColors.paleSage.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: isDark
                                  ? SproutColors.nightAccent
                                  : SproutColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          // Non-interfering Animated Typewriter Hint Overlay
          if (showTypewriter)
            Positioned(
              left: 48,
              right: 88,
              child: IgnorePointer(
                child: SproutTypewriterHint(
                  suggestions: widget.animatedHints!,
                  isPaused: _hasFocus || _hasText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
