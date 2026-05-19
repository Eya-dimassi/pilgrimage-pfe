import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  factory AuthException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return AuthException(message);
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      if (kDebugMode) {
        final uri = error.requestOptions.uri.toString();
        final reason = error.error?.toString();
        if (reason != null && reason.trim().isNotEmpty) {
          return AuthException(
            '${'auth_exception.unreachable_server'.tr()}\n$uri\n$reason',
          );
        }
        return AuthException(
          '${'auth_exception.unreachable_server'.tr()}\n$uri',
        );
      }
      return AuthException('auth_exception.unreachable_server'.tr());
    }

    return AuthException('auth_exception.generic_error'.tr());
  }

  @override
  String toString() => message;
}
