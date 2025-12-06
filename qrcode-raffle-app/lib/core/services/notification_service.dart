import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

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

/// Service to handle push notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
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
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Setup background/terminated message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('Notification permission: ${settings.authorizationStatus}');
    return isAuthorized;
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

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification when app is in foreground
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    onNotificationTap?.call(jsonEncode(message.data));
  }

  /// Get FCM token for device
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to token refresh
  void onTokenRefresh(Function(String) callback) {
    _messaging.onTokenRefresh.listen(callback);
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
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
