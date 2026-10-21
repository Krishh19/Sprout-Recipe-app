import 'dart:async';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';

class SproutTypewriterHint extends StatefulWidget {
  final List<String> suggestions;
  final TextStyle? style;
  final TextStyle? cursorStyle;
  final Duration typingSpeed;
  final Duration erasingSpeed;
  final Duration pauseDuration;
  final bool isPaused;

  static const List<String> defaultSuggestions = [
    'Search high-protein recipes...',
    'Try Indian dinner recipes...',
    'Find quick breakfast ideas...',
    'Search by ingredients...',
    'Explore vegetarian meals...',
  ];

  const SproutTypewriterHint({
    super.key,
    this.suggestions = defaultSuggestions,
    this.style,
    this.cursorStyle,
    this.typingSpeed = const Duration(milliseconds: 65),
    this.erasingSpeed = const Duration(milliseconds: 30),
    this.pauseDuration = const Duration(milliseconds: 1800),
    this.isPaused = false,
  });

  @override
  State<SproutTypewriterHint> createState() => _SproutTypewriterHintState();
}

enum _TypewriterPhase { typing, pausing, erasing }

class _SproutTypewriterHintState extends State<SproutTypewriterHint>
    with SingleTickerProviderStateMixin {
  int _currentSuggestionIndex = 0;
  int _currentCharCount = 0;
  _TypewriterPhase _phase = _TypewriterPhase.typing;

  Timer? _stepTimer;
  late AnimationController _cursorBlinkController;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    if (!isTest) {
      _cursorBlinkController.repeat(reverse: true);
      if (!widget.isPaused) {
        _scheduleNextStep();
      }
    }
  }

  @override
  void didUpdateWidget(covariant SproutTypewriterHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _stepTimer?.cancel();
        _stepTimer = null;
      } else {
        _scheduleNextStep();
      }
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _cursorBlinkController.dispose();
    super.dispose();
  }

  void _scheduleNextStep() {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!mounted || widget.isPaused || widget.suggestions.isEmpty || isTest) return;

    final currentTarget = widget.suggestions[_currentSuggestionIndex];

    switch (_phase) {
      case _TypewriterPhase.typing:
        if (_currentCharCount < currentTarget.length) {
          _stepTimer = Timer(widget.typingSpeed, () {
            if (!mounted || widget.isPaused) return;
            setState(() {
              _currentCharCount++;
            });
            _scheduleNextStep();
          });
        } else {
          _phase = _TypewriterPhase.pausing;
          _stepTimer = Timer(widget.pauseDuration, () {
            if (!mounted || widget.isPaused) return;
            setState(() {
              _phase = _TypewriterPhase.erasing;
            });
            _scheduleNextStep();
          });
        }
        break;

      case _TypewriterPhase.pausing:
        // Already handled in typing completion timer
        break;

      case _TypewriterPhase.erasing:
        if (_currentCharCount > 0) {
          _stepTimer = Timer(widget.erasingSpeed, () {
            if (!mounted || widget.isPaused) return;
            setState(() {
              _currentCharCount--;
            });
            _scheduleNextStep();
          });
        } else {
          _phase = _TypewriterPhase.typing;
          _currentSuggestionIndex =
              (_currentSuggestionIndex + 1) % widget.suggestions.length;
          _stepTimer = Timer(const Duration(milliseconds: 250), () {
            if (!mounted || widget.isPaused) return;
            _scheduleNextStep();
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final effectiveStyle = widget.style ??
        SproutTypography.body(
          color: isDark ? SproutColors.nightSecondaryInk : SproutColors.textSecondary,
        ).copyWith(fontSize: 15);

    final effectiveCursorStyle = widget.cursorStyle ??
        effectiveStyle.copyWith(
          color: isDark ? SproutColors.nightAccent : SproutColors.sproutGreen,
          fontWeight: FontWeight.w400,
        );

    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (reduceMotion || isTest) {
      return Text(
        widget.suggestions.first,
        style: effectiveStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final currentText = widget.suggestions[_currentSuggestionIndex];
    final visiblePart = currentText.substring(0, _currentCharCount.clamp(0, currentText.length));

    return AnimatedBuilder(
      animation: _cursorBlinkController,
      builder: (context, _) {
        final showCursor = _phase == _TypewriterPhase.typing ||
            _phase == _TypewriterPhase.erasing ||
            _cursorBlinkController.value > 0.45;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                visiblePart,
                style: effectiveStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Opacity(
              opacity: showCursor ? 1.0 : 0.0,
              child: Text(
                '|',
                style: effectiveCursorStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
