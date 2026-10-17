import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'tutorial_storage.dart';
import 'tutorial_targets.dart';

/// Controller coordinating Sprout's in-app feature discovery tours.
class TutorialManager {
  final TutorialStorage _storage;
  bool _isTourRunning = false;

  TutorialManager(this._storage);

  /// Whether a showcase tour is currently active.
  bool get isTourRunning => _isTourRunning;

  /// Whether the user should be shown the main tour automatically.
  bool shouldShowMainTour() => _storage.shouldShowMainTour();

  /// Marks the main tour completed.
  Future<void> markMainTourCompleted() async {
    _isTourRunning = false;
    await _storage.markMainTourCompleted();
  }

  /// Marks the main tour skipped.
  Future<void> markMainTourSkipped() async {
    _isTourRunning = false;
    await _storage.markMainTourSkipped();
  }

  /// Resets the main tour state.
  Future<void> resetMainTour() async {
    _isTourRunning = false;
    await _storage.resetMainTour();
  }

  /// Initiates the main 5-step tour on the provided context if eligible.
  void startMainTour(BuildContext context, {bool force = false}) {
    if (_isTourRunning) return;
    if (!force && !shouldShowMainTour()) return;

    _isTourRunning = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        _isTourRunning = false;
        return;
      }

      try {
        final allKeys = TutorialTargets.instance.mainTourKeys;
        // Gracefully filter for keys whose widgets are currently mounted/rendered
        final validKeys = allKeys.where((key) {
          try {
            return ShowcaseView.get().isTargetRendered(key) ||
                key.currentContext != null;
          } catch (_) {
            return key.currentContext != null;
          }
        }).toList();

        if (validKeys.isEmpty) {
          _isTourRunning = false;
          return;
        }

        ShowcaseView.get().startShowCase(validKeys);
      } catch (e) {
        _isTourRunning = false;
      }
    });
  }

  /// Called by ShowcaseView onFinish
  void onTourFinished() {
    _isTourRunning = false;
    _storage.markMainTourCompleted();
  }

  /// User skipped the tour from the coach mark.
  void skip(BuildContext context) {
    _isTourRunning = false;
    _storage.markMainTourSkipped();
    try {
      ShowcaseView.get().dismiss();
    } catch (_) {}
  }

  /// User completed the final tour step.
  void complete(BuildContext context) {
    _isTourRunning = false;
    _storage.markMainTourCompleted();
    try {
      ShowcaseView.get().dismiss();
    } catch (_) {}
  }

  /// Advances to the next tour step.
  void next(BuildContext context) {
    try {
      ShowcaseView.get().next();
    } catch (_) {}
  }

  /// Reverts to the previous tour step.
  void previous(BuildContext context) {
    try {
      ShowcaseView.get().previous();
    } catch (_) {}
  }

  /// Restarts the main tour from anywhere in the app (e.g. Profile screen).
  void restart(
    BuildContext context, {
    required void Function(int tabIndex) onSwitchTab,
  }) {
    _storage.resetMainTour();
    _isTourRunning = false;
    // Switch to Home screen where targets are mounted
    onSwitchTab(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      startMainTour(context, force: true);
    });
  }
}

/// Provider for TutorialStorage instance (defaults to in-memory fallback unless overridden in main.dart).
final tutorialStorageProvider = Provider<TutorialStorage>((ref) {
  return TutorialStorage();
});

/// Provider for TutorialManager instance.
final tutorialManagerProvider = Provider<TutorialManager>((ref) {
  final storage = ref.watch(tutorialStorageProvider);
  return TutorialManager(storage);
});
