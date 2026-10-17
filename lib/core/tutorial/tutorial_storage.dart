import 'package:shared_preferences/shared_preferences.dart';

/// Manages local persistence for Sprout's in-app feature discovery tours.
class TutorialStorage {
  static const String _mainCompletedKey = 'sprout_tutorial_main_v1_completed';
  static const String _mainSkippedKey = 'sprout_tutorial_main_v1_skipped';

  final SharedPreferences? _prefs;
  final Map<String, bool> _inMemoryFallback = {};

  TutorialStorage([this._prefs]);

  static Future<TutorialStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TutorialStorage(prefs);
  }

  /// Whether the user has previously completed the main feature tour.
  bool isMainTourCompleted() {
    if (_prefs != null) {
      return _prefs.getBool(_mainCompletedKey) ?? false;
    }
    return _inMemoryFallback[_mainCompletedKey] ?? false;
  }

  /// Whether the user explicitly skipped the main feature tour.
  bool isMainTourSkipped() {
    if (_prefs != null) {
      return _prefs.getBool(_mainSkippedKey) ?? false;
    }
    return _inMemoryFallback[_mainSkippedKey] ?? false;
  }

  /// The tour should only show automatically if neither completed nor skipped.
  bool shouldShowMainTour() {
    return !isMainTourCompleted() && !isMainTourSkipped();
  }

  /// Marks the main tour as completed.
  Future<void> markMainTourCompleted() async {
    if (_prefs != null) {
      await _prefs.setBool(_mainCompletedKey, true);
    } else {
      _inMemoryFallback[_mainCompletedKey] = true;
    }
  }

  /// Marks the main tour as skipped.
  Future<void> markMainTourSkipped() async {
    if (_prefs != null) {
      await _prefs.setBool(_mainSkippedKey, true);
    } else {
      _inMemoryFallback[_mainSkippedKey] = true;
    }
  }

  /// Resets the main tour state so it can be re-run manually.
  Future<void> resetMainTour() async {
    if (_prefs != null) {
      await _prefs.remove(_mainCompletedKey);
      await _prefs.remove(_mainSkippedKey);
    } else {
      _inMemoryFallback.clear();
    }
  }
}
