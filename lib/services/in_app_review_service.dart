import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  static const String _lastPromptKey = 'sprout_last_in_app_review_prompt';
  static const int _cooldownDays = 30;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Conditionally requests an in-app review if available and outside cooldown.
  Future<bool> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPromptEpoch = prefs.getInt(_lastPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLast = (now - lastPromptEpoch) ~/ (1000 * 60 * 60 * 24);

      if (daysSinceLast < _cooldownDays) {
        debugPrint('InAppReview: In cooldown ($daysSinceLast/$_cooldownDays days)');
        return false;
      }

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setInt(_lastPromptKey, now);
        return true;
      }
    } catch (e) {
      debugPrint('InAppReview error: $e');
    }
    return false;
  }
}
