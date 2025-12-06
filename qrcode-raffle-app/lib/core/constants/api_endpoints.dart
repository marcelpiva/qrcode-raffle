class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - will be configured per environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.100:5001/api',
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
  static String raffleConfirmPin(String id) => '/raffles/$id/confirm-pin';
  static String raffleReopen(String id) => '/raffles/$id/reopen';
  static String raffleExport(String id) => '/raffles/$id/export';
  static String raffleParticipants(String id) => '/raffles/$id/participants';
  static const String raffleCreateFromRanking = '/raffles/create-from-ranking';

  // Registration endpoints (public)
  static String registerParticipant(String id) => '/register/$id';
  static String confirmPresence(String id) => '/confirm/$id';

  // Events endpoints
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';
  static String eventEligibleCount(String id) => '/events/$id/eligible-count';

  // Tracks endpoints
  static const String tracks = '/tracks';
  static String trackById(String id) => '/tracks/$id';

  // Talks endpoints
  static const String talks = '/talks';
  static String talkById(String id) => '/talks/$id';
  static String talkAttendance(String id) => '/talks/$id/attendance';
  static String talkAttendanceById(String talkId, String attendanceId) =>
      '/talks/$talkId/attendance/$attendanceId';

  // Ranking endpoints
  static const String ranking = '/ranking';
  static const String rankingEvents = '/ranking/events';
  static const String rankingTracks = '/ranking/tracks';
  static const String rankingCreateRaffle = '/ranking/create-raffle';
  static const String createVipRaffle = '/ranking/create-vip';

  // Utility endpoints
  static const String serverTime = '/time';
  static const String health = '/health';
  static const String version = '/version';
}
