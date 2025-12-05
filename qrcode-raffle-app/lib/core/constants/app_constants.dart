class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'QR Code Raffle';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String fcmTokenKey = 'fcm_token';
  static const String onboardingKey = 'onboarding_completed';

  // Token expiration
  static const int accessTokenExpirationMinutes = 15;
  static const int refreshTokenExpirationDays = 7;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;

  // PIN
  static const int pinLength = 5;

  // Animation durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 400;
  static const int longAnimationDuration = 800;
  static const int slotMachineAnimationDuration = 5000;

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
}
