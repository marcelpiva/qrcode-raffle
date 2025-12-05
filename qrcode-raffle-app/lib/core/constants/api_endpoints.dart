class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - will be configured per environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String fcmToken = '/auth/fcm-token';

  // Raffles endpoints
  static const String raffles = '/raffles';
  static String raffleById(String id) => '/raffles/$id';
  static String raffleDraw(String id) => '/raffles/$id/draw';
  static String raffleConfirmWinner(String id) => '/raffles/$id/confirm-winner';
  static String raffleReopen(String id) => '/raffles/$id/reopen';
  static String raffleExport(String id) => '/raffles/$id/export';
  static String raffleParticipants(String id) => '/raffles/$id/participants';

  // Registration endpoints (public)
  static String registerParticipant(String id) => '/register/$id';
  static String confirmPresence(String id) => '/confirm/$id';

  // Ranking endpoints
  static const String ranking = '/ranking';
  static const String createVipRaffle = '/ranking/create-vip';

  // Utility endpoints
  static const String serverTime = '/time';
  static const String health = '/health';
}
