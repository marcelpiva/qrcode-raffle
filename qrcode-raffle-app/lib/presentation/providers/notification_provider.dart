import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import 'auth_provider.dart';

/// State for notification settings
class NotificationState {
  final bool isInitialized;
  final bool hasPermission;
  final String? fcmToken;
  final String? error;

  const NotificationState({
    this.isInitialized = false,
    this.hasPermission = false,
    this.fcmToken,
    this.error,
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? hasPermission,
    String? fcmToken,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      fcmToken: fcmToken ?? this.fcmToken,
      error: error,
    );
  }
}

/// Notifier for notification state management
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final Ref _ref;

  NotificationNotifier(this._notificationService, this._ref)
      : super(const NotificationState());

  /// Initialize notifications
  Future<void> initialize() async {
    if (state.isInitialized) return;

    try {
      await _notificationService.initialize();

      // Get and register FCM token
      final token = await _notificationService.getToken();

      if (token != null) {
        // Register token with backend
        await _registerToken(token);
      }

      // Listen for token refresh
      _notificationService.onTokenRefresh((newToken) async {
        await _registerToken(newToken);
        state = state.copyWith(fcmToken: newToken);
      });

      state = state.copyWith(
        isInitialized: true,
        hasPermission: true,
        fcmToken: token,
      );

      debugPrint('Notifications initialized with token: ${token?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      state = state.copyWith(
        isInitialized: true,
        hasPermission: false,
        error: e.toString(),
      );
    }
  }

  /// Register FCM token with backend
  Future<void> _registerToken(String token) async {
    try {
      await _ref.read(authStateProvider.notifier).updateFcmToken(token);
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Set navigation callback for notification taps
  void setNavigationCallback(Function(String route) navigateTo) {
    NotificationHandler(
      notificationService: _notificationService,
      navigateTo: navigateTo,
    );
  }

  /// Subscribe to raffle topic for updates
  Future<void> subscribeToRaffle(String raffleId) async {
    await _notificationService.subscribeToTopic('raffle_$raffleId');
  }

  /// Unsubscribe from raffle topic
  Future<void> unsubscribeFromRaffle(String raffleId) async {
    await _notificationService.unsubscribeFromTopic('raffle_$raffleId');
  }

  /// Show local notification (for testing)
  Future<void> showTestNotification() async {
    await _notificationService.showLocalNotification(
      title: 'QR Code Raffle',
      body: 'Notificações configuradas com sucesso!',
    );
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Handle logout - delete FCM token
  Future<void> onLogout() async {
    await _notificationService.deleteToken();
    state = state.copyWith(fcmToken: null);
  }
}

/// Provider for notification notifier
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService, ref);
});

/// Simple provider to check if notifications are enabled
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).hasPermission;
});
