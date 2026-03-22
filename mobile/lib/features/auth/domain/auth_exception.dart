import 'package:dio/dio.dart';

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
      return const AuthException('Impossible de joindre le serveur');
    }

    return const AuthException('Une erreur est survenue');
  }

  @override
  String toString() => message;
}
