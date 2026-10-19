import 'dart:ui';
import 'package:flutter/material.dart';
import '../colors.dart';

class SproutScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool showStatusBarScrim;
  final Gradient? backgroundGradient;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const SproutScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.showStatusBarScrim = false,
    this.backgroundGradient,
    this.extendBody = false,
    this.extendBodyBehindAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final bg = backgroundColor ?? SproutColors.canvas;
    final effectiveGradient = backgroundGradient ??
        (backgroundColor == null ? SproutColors.backgroundGradient : null);

    Widget effectiveBody = body;
    if (showStatusBarScrim && topPadding > 0 && appBar == null) {
      effectiveBody = Stack(
        children: [
          body,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? SproutColors.nightSkyTop : SproutColors.lightSkyTop)
                          .withValues(alpha: 0.70),
                      border: Border(
                        bottom: BorderSide(
                          color: SproutColors.sage.withValues(alpha: 0.12),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: effectiveGradient != null ? Colors.transparent : bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: effectiveGradient != null
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: effectiveGradient),
                  ),
                ),
                effectiveBody,
              ],
            )
          : effectiveBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

