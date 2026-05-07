import 'package:dio/dio.dart';

class PresenceException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  PresenceException({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory PresenceException.fromDio(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = data is Map ? (data['message'] ?? 'Erreur serveur') : 'Erreur serveur';
      
      return PresenceException(
        message: message,
        statusCode: e.response?.statusCode,
        code: data is Map ? data['code'] : null,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return PresenceException(
          message: 'Délai de connexion dépassé',
          code: 'CONNECTION_TIMEOUT',
        );
      case DioExceptionType.receiveTimeout:
        return PresenceException(
          message: 'Délai de réception dépassé',
          code: 'RECEIVE_TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return PresenceException(
          message: 'Erreur de connexion. Vérifiez votre réseau.',
          code: 'CONNECTION_ERROR',
        );
      default:
        return PresenceException(
          message: e.message ?? 'Erreur inconnue',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  @override
  String toString() => message;
}