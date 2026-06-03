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
        return AuthException(_localizedServerMessage(message));
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

String _localizedServerMessage(String message) {
  switch (message.trim()) {
    case 'Nom, prenom, email, mot de passe et code unique requis':
      return 'family_signup.validation.required_fields'.tr();
    case 'Mot de passe trop court (8 caracteres minimum)':
      return 'family_signup.validation.password_too_short'.tr();
    case 'Un compte avec cet email existe deja':
      return 'family_signup.validation.email_exists'.tr();
    case 'Code unique pelerin introuvable':
    case 'Aucun pelerin correspondant a ce code unique':
      return 'family_signup.validation.pilgrim_code_not_found'.tr();
    case 'Code unique requis':
      return 'family_signup.validation.pilgrim_code_required'.tr();
    case 'Compte famille introuvable':
      return 'family_home.add_relative_sheet.family_account_not_found'.tr();
    case 'Ce pelerin n appartient pas a la meme agence':
      return 'family_home.add_relative_sheet.different_agency'.tr();
    case 'Ce proche est deja lie a votre compte':
      return 'family_home.add_relative_sheet.already_linked'.tr();
    default:
      return message;
  }
}
