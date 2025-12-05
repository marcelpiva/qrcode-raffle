import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/participant/qr_scanner_screen.dart';
import '../../presentation/screens/participant/register_screen.dart';
import '../../presentation/screens/participant/confirmation_screen.dart';
import '../../presentation/screens/admin/dashboard_screen.dart';
import '../../presentation/screens/admin/raffle_list_screen.dart';
import '../../presentation/screens/admin/raffle_detail_screen.dart';
import '../../presentation/screens/admin/create_raffle_screen.dart';
import '../../presentation/screens/admin/draw_screen.dart';
import '../../presentation/screens/admin/ranking_screen.dart';
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
        return isLoggedIn ? '/home' : '/qr-scanner';
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

      // Home (Tab Container)
      GoRoute(
        path: '/home',
        name: 'home',
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
            builder: (context, state) => const CreateRaffleScreen(),
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
