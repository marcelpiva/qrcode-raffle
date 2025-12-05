import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._dioClient, this._secureStorage)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final isLoggedIn = await _secureStorage.isLoggedIn();
      if (isLoggedIn) {
        final userData = await _secureStorage.getUserData();
        if (userData != null) {
          final userModel = UserModel.fromJson(jsonDecode(userData));
          state = AsyncValue.data(AuthState(
            user: userModel.toEntity(),
            isAuthenticated: true,
          ));
          return;
        }
      }
      state = const AsyncValue.data(AuthState());
    } catch (e) {
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: LoginRequest(email: email, password: password).toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Store tokens
      await _secureStorage.setAccessToken(authResponse.accessToken);
      await _secureStorage.setRefreshToken(authResponse.refreshToken);
      await _secureStorage.setUserData(jsonEncode(authResponse.user.toJson()));

      state = AsyncValue.data(AuthState(
        user: authResponse.user.toEntity(),
        isAuthenticated: true,
      ));
    } on AuthException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } on ServerException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } on NetworkException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: 'Erro ao fazer login: $e'));
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await _dioClient.post(
        ApiEndpoints.register,
        data: RegisterRequest(
          name: name,
          email: email,
          password: password,
        ).toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Store tokens
      await _secureStorage.setAccessToken(authResponse.accessToken);
      await _secureStorage.setRefreshToken(authResponse.refreshToken);
      await _secureStorage.setUserData(jsonEncode(authResponse.user.toJson()));

      state = AsyncValue.data(AuthState(
        user: authResponse.user.toEntity(),
        isAuthenticated: true,
      ));
    } on ValidationException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } on ConflictException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } on ServerException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } on NetworkException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: 'Erro ao registrar: $e'));
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dioClient.post(
          ApiEndpoints.logout,
          data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
        );
      }
    } catch (_) {
      // Ignore errors during logout
    } finally {
      await _secureStorage.clearAuthData();
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _dioClient.post(
        ApiEndpoints.fcmToken,
        data: {'fcmToken': token},
      );
      await _secureStorage.setFcmToken(token);
    } catch (_) {
      // Ignore errors
    }
  }

  void clearError() {
    final currentState = state.valueOrNull ?? const AuthState();
    state = AsyncValue.data(currentState.copyWith(error: null));
  }
}

// Providers
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(dioClient, secureStorage);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.isAuthenticated ?? false;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});
