import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SproutNotificationService {
  static final SproutNotificationService _instance = SproutNotificationService._internal();
  factory SproutNotificationService() => _instance;
  SproutNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  static const String _timerChannelId = 'sprout_cooking_timer_channel';
  static const String _timerChannelName = 'Cooking Timers';
  static const String _timerChannelDesc = 'Active cooking step timers and alerts';

  static const String _pantryChannelId = 'sprout_pantry_expiry_channel';
  static const String _pantryChannelName = 'Pantry Freshness';
  static const String _pantryChannelDesc = 'Reminders for ingredients nearing expiration';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (running on unsupported platform or test): $e');
    }
  }

  /// Shows or updates the ongoing cooking timer notification.
  Future<void> showTimerProgress({
    int id = 1001,
    required String recipeTitle,
    required String stepDescription,
    required int secondsRemaining,
    required int totalSeconds,
  }) async {
    if (!_isInitialized) await initialize();

    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    try {
      final androidDetails = AndroidNotificationDetails(
        _timerChannelId,
        _timerChannelName,
        channelDescription: _timerChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: totalSeconds,
        progress: totalSeconds - secondsRemaining,
        onlyAlertOnce: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: id,
        title: '🍳 $timeStr - $recipeTitle',
        body: stepDescription,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showTimerProgress error: $e');
    }
  }

  /// Triggers a high-priority alert chime when a cooking timer finishes.
  Future<void> showTimerComplete({
    int id = 1001,
    required String recipeTitle,
    required String stepDescription,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final androidDetails = AndroidNotificationDetails(
        _timerChannelId,
        _timerChannelName,
        channelDescription: _timerChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: id,
        title: '⏰ Timer Finished! - $recipeTitle',
        body: 'Your timer for "$stepDescription" is complete.',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showTimerComplete error: $e');
    }
  }

  /// Cancels an active notification by ID.
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  /// Shows a notification when ingredients in the pantry are expiring soon.
  Future<void> showPantryExpiryAlert({
    int id = 2001,
    required List<String> expiringItems,
  }) async {
    if (!_isInitialized) await initialize();
    if (expiringItems.isEmpty) return;

    try {
      final itemsStr = expiringItems.take(3).join(', ');
      final title = '🌱 Use them before they spoil!';
      final body = '$itemsStr ${expiringItems.length > 3 ? '+more' : ''} are expiring soon. Check recipes you can make!';

      const androidDetails = AndroidNotificationDetails(
        _pantryChannelId,
        _pantryChannelName,
        channelDescription: _pantryChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showPantryExpiryAlert error: $e');
    }
  }
}
