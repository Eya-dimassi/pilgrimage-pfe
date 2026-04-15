import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  Future<Map<String, String>>? refreshFuture;

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final shouldRefresh =
            error.response?.statusCode == 401 &&
            request.path != ApiEndpoints.login &&
            request.path != ApiEndpoints.refresh &&
            request.extra['skipAuthRefresh'] != true;

        if (!shouldRefresh) {
          handler.next(error);
          return;
        }

        try {
          refreshFuture ??= _refreshTokens(
            refreshDio: refreshDio,
            storage: storage,
          ).whenComplete(() {
            refreshFuture = null;
          });

          final tokens = await refreshFuture!;
          final retryOptions = Options(
            method: request.method,
            headers: {
              ...request.headers,
              'Authorization': 'Bearer ${tokens['accessToken']}',
            },
            responseType: request.responseType,
            contentType: request.contentType,
            sendTimeout: request.sendTimeout,
            receiveTimeout: request.receiveTimeout,
            extra: {
              ...request.extra,
              'skipAuthRefresh': true,
            },
          );

          final response = await dio.request<dynamic>(
            request.path,
            data: request.data,
            queryParameters: request.queryParameters,
            options: retryOptions,
          );

          handler.resolve(response);
        } on DioException catch (refreshError) {
          await ref.read(authProvider.notifier).expireSession();
          handler.next(refreshError);
        } catch (_) {
          await ref.read(authProvider.notifier).expireSession();
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});

Future<Map<String, String>> _refreshTokens({
  required Dio refreshDio,
  required SecureStorageService storage,
}) async {
  final refreshToken = await storage.readRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) {
    throw DioException(
      requestOptions: RequestOptions(path: ApiEndpoints.refresh),
      error: 'Missing refresh token',
    );
  }

  final response = await refreshDio.post<Map<String, dynamic>>(
    ApiEndpoints.refresh,
    data: {'refreshToken': refreshToken},
  );

  final accessToken = response.data?['accessToken'] as String? ?? '';
  final nextRefreshToken = response.data?['refreshToken'] as String? ?? '';

  if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
    throw DioException(
      requestOptions: RequestOptions(path: ApiEndpoints.refresh),
      error: 'Invalid refresh payload',
    );
  }

  await storage.updateSessionTokens(
    accessToken: accessToken,
    refreshToken: nextRefreshToken,
  );

  return {
    'accessToken': accessToken,
    'refreshToken': nextRefreshToken,
  };
}
