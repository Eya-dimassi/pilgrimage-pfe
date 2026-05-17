import 'package:dio/dio.dart';
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
            'Impossible de joindre le serveur\n$uri\n$reason',
          );
        }
        return AuthException('Impossible de joindre le serveur\n$uri');
      }
      return const AuthException('Impossible de joindre le serveur');
    }

    return const AuthException('Une erreur est survenue');
  }

  @override
  String toString() => message;
}
