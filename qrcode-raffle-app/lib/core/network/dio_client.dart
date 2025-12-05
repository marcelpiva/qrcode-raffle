import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import '../errors/exceptions.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage);
});

class DioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this, _secureStorage),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Tempo de conexão esgotado',
        );

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map ? data['message'] : 'Erro no servidor';

        switch (statusCode) {
          case 400:
            return ValidationException(
              message: message ?? 'Dados inválidos',
              fieldErrors: data is Map ? _extractFieldErrors(data) : null,
            );
          case 401:
            return AuthException(message: message ?? 'Não autorizado');
          case 403:
            return const AuthException(message: 'Acesso negado');
          case 404:
            return NotFoundException(message: message ?? 'Não encontrado');
          case 409:
            return ConflictException(message: message ?? 'Conflito de dados');
          default:
            return ServerException(
              message: message ?? 'Erro no servidor',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return const ServerException(message: 'Requisição cancelada');

      default:
        return const ServerException(message: 'Erro desconhecido');
    }
  }

  Map<String, String>? _extractFieldErrors(Map data) {
    if (data['errors'] is Map) {
      return (data['errors'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return null;
  }

  Future<bool> refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        await _secureStorage.clearAuthData();
        return false;
      }

      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': ''}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'];
        await _secureStorage.setAccessToken(newAccessToken);
        return true;
      }

      await _secureStorage.clearAuthData();
      return false;
    } catch (e) {
      await _secureStorage.clearAuthData();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final DioClient _client;
  final SecureStorageService _secureStorage;

  _AuthInterceptor(this._client, this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final publicEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refresh,
    ];

    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    // Skip if it's a registration endpoint (starts with /register/)
    final isRegistrationEndpoint = options.path.startsWith('/register/');

    if (!isPublicEndpoint && !isRegistrationEndpoint) {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Don't retry for login/register endpoints
      if (err.requestOptions.path.contains(ApiEndpoints.login) ||
          err.requestOptions.path.contains(ApiEndpoints.register)) {
        handler.next(err);
        return;
      }

      // Try to refresh token
      final refreshed = await _client.refreshToken();
      if (refreshed) {
        // Retry the original request
        try {
          final token = await _secureStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';

          final response = await _client.dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      }
    }

    handler.next(err);
  }
}
