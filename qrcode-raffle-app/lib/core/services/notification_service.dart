import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: Firebase Messaging temporarily disabled due to iOS build issue with modular headers
// TODO: Re-enable when firebase_messaging 15+ is available and compatible

/// Notification types from backend
enum NotificationType {
  winnerAnnouncement,
  raffleOpening,
  raffleClosing,
  raffleStartingSoon,
  confirmationReminder,
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service to handle push notifications (stub version without Firebase Messaging)
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'qrcode_raffle_channel',
    'QR Code Raffle',
    description: 'Notificações do sistema de sorteios',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Callback for when user taps notification
  Function(String? payload)? onNotificationTap;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();
    debugPrint('NotificationService initialized (stub mode - no FCM)');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Get FCM token for device (stub - returns null)
  Future<String?> getToken() async {
    debugPrint('FCM not available - returning null token');
    return null;
  }

  /// Subscribe to token refresh (stub - no-op)
  void onTokenRefresh(Function(String) callback) {
    debugPrint('FCM not available - token refresh disabled');
  }

  /// Subscribe to topic (stub - no-op)
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('FCM not available - topic subscription disabled');
  }

  /// Unsubscribe from topic (stub - no-op)
  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('FCM not available - topic unsubscription disabled');
  }

  /// Delete FCM token (stub - no-op)
  Future<void> deleteToken() async {
    debugPrint('FCM not available - token deletion disabled');
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

/// Parse notification payload and navigate accordingly
class NotificationHandler {
  final NotificationService _notificationService;
  final Function(String route)? navigateTo;

  NotificationHandler({
    required NotificationService notificationService,
    this.navigateTo,
  }) : _notificationService = notificationService {
    _notificationService.onNotificationTap = _handlePayload;
  }

  void _handlePayload(String? payload) {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final raffleId = data['raffleId'] as String?;

      switch (type) {
        case 'winner_announcement':
          if (raffleId != null) {
            navigateTo?.call('/admin/raffles/$raffleId');
          }
          break;
        case 'raffle_opening':
        case 'raffle_closing':
        case 'raffle_starting':
          if (raffleId != null) {
            navigateTo?.call('/participate/$raffleId');
          }
          break;
        case 'confirmation_reminder':
          if (raffleId != null) {
            navigateTo?.call('/confirm/$raffleId');
          }
          break;
        default:
          navigateTo?.call('/home');
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }
}
