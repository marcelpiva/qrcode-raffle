import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/landing/events_carousel_screen.dart';
import '../../presentation/screens/participant/qr_scanner_screen.dart';
import '../../presentation/screens/participant/register_screen.dart';
import '../../presentation/screens/participant/confirmation_screen.dart';
import '../../presentation/screens/admin/dashboard_screen.dart';
import '../../presentation/screens/admin/raffle_list_screen.dart';
import '../../presentation/screens/admin/raffle_detail_screen.dart';
import '../../presentation/screens/admin/create_raffle_screen.dart';
import '../../presentation/screens/admin/draw_screen.dart';
import '../../presentation/screens/admin/ranking_screen.dart';
import '../../presentation/screens/admin/events_list_screen.dart';
import '../../presentation/screens/admin/event_detail_screen.dart';
import '../../presentation/screens/admin/track_detail_screen.dart';
import '../../presentation/screens/admin/talk_detail_screen.dart';
import '../../presentation/screens/admin/event_wizard_screen.dart';
import '../../presentation/screens/admin/create_track_screen.dart';
import '../../presentation/screens/admin/create_talk_screen.dart';
import '../../presentation/screens/admin/add_attendance_screen.dart';
import '../../presentation/screens/display_screen.dart';
import '../../presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoading = authState.isLoading;
      final currentPath = state.uri.path;

      // Allow splash screen while loading
      if (isLoading && currentPath == '/') {
        return null;
      }

      // Public routes that don't require auth
      final publicRoutes = [
        '/login',
        '/register',
        '/qr-scanner',
      ];

      // Routes that start with these prefixes are public
      final publicPrefixes = [
        '/participate/',
        '/confirm/',
        '/display/',
      ];

      final isPublicRoute = publicRoutes.contains(currentPath) ||
          publicPrefixes.any((prefix) => currentPath.startsWith(prefix));

      // If loading, stay on current route
      if (isLoading) {
        return null;
      }

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute && currentPath != '/') {
        return '/login';
      }

      // If logged in and on login page, redirect to home
      if (isLoggedIn && currentPath == '/login') {
        return '/home';
      }

      // If on splash and auth is determined, redirect appropriately
      if (currentPath == '/' && !isLoading) {
        return '/home'; // Always go to home for demo
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Home (Carousel Landing)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const EventsCarouselScreen(),
      ),

      // Dashboard (Old Home with tabs)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const HomeScreen(),
      ),

      // Participant Routes (Public)
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/participate/:raffleId',
        name: 'participate',
        builder: (context, state) {
          final raffleId = state.pathParameters['raffleId']!;
          return RegisterScreen(raffleId: raffleId);
        },
      ),
      GoRoute(
        path: '/confirm/:raffleId',
        name: 'confirm-presence',
        builder: (context, state) {
          final raffleId = state.pathParameters['raffleId']!;
          return ConfirmationScreen(raffleId: raffleId);
        },
      ),

      // Display Route (for projection)
      GoRoute(
        path: '/display/:raffleId',
        name: 'display',
        builder: (context, state) {
          final raffleId = state.pathParameters['raffleId']!;
          return DisplayScreen(raffleId: raffleId);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'raffles',
            name: 'raffle-list',
            builder: (context, state) => const RaffleListScreen(),
          ),
          GoRoute(
            path: 'raffles/new',
            name: 'create-raffle',
            builder: (context, state) {
              final eventId = state.uri.queryParameters['eventId'];
              final talkId = state.uri.queryParameters['talkId'];
              return CreateRaffleScreen(
                initialEventId: eventId,
                initialTalkId: talkId,
              );
            },
          ),
          GoRoute(
            path: 'raffles/create',
            name: 'create-raffle-from-event',
            builder: (context, state) {
              final eventId = state.uri.queryParameters['eventId'];
              final talkId = state.uri.queryParameters['talkId'];
              return CreateRaffleScreen(
                initialEventId: eventId,
                initialTalkId: talkId,
              );
            },
          ),
          GoRoute(
            path: 'raffles/:id',
            name: 'raffle-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RaffleDetailScreen(raffleId: id);
            },
          ),
          GoRoute(
            path: 'raffles/:id/draw',
            name: 'draw',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DrawScreen(raffleId: id);
            },
          ),
          GoRoute(
            path: 'ranking',
            name: 'ranking',
            builder: (context, state) => const RankingScreen(),
          ),
          // Events routes
          GoRoute(
            path: 'events',
            name: 'events-list',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: 'events/new',
            name: 'create-event',
            builder: (context, state) => const EventWizardScreen(),
          ),
          GoRoute(
            path: 'events/:id',
            name: 'event-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EventDetailScreen(eventId: id);
            },
          ),
          GoRoute(
            path: 'events/:eventId/tracks/new',
            name: 'create-track',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return CreateTrackScreen(eventId: eventId);
            },
          ),
          GoRoute(
            path: 'tracks/:id',
            name: 'track-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TrackDetailScreen(trackId: id);
            },
          ),
          GoRoute(
            path: 'tracks/:trackId/talks/new',
            name: 'create-talk',
            builder: (context, state) {
              final trackId = state.pathParameters['trackId']!;
              return CreateTalkScreen(trackId: trackId);
            },
          ),
          GoRoute(
            path: 'talks/:id',
            name: 'talk-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TalkDetailScreen(talkId: id);
            },
          ),
          GoRoute(
            path: 'talks/:talkId/attendances/new',
            name: 'add-attendance',
            builder: (context, state) {
              final talkId = state.pathParameters['talkId']!;
              return AddAttendanceScreen(talkId: talkId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.path),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  );
});
