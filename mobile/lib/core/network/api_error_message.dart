import 'dart:convert';

import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  // Network / transport errors (no HTTP status)
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La connexion est trop lente. Réessayez.';
    case DioExceptionType.connectionError:
      return 'Impossible de se connecter. Vérifiez votre connexion internet puis réessayez.';
    case DioExceptionType.badCertificate:
      return 'Connexion sécurisée impossible. Réessayez.';
    case DioExceptionType.cancel:
      return 'Requête annulée. Réessayez.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final status = error.response?.statusCode;
  final serverMessage = _extractServerMessage(error.response?.data);

  // If backend provides a clean message, prefer it (avoid printing raw JSON/maps)
  if (serverMessage != null && serverMessage.isNotEmpty) {
    // Still override a few common cases to keep UX consistent.
    if (status == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (status == 403) {
      return "Accès refusé. Vous n'avez pas l'autorisation.";
    }
    return serverMessage;
  }

  if (status == null) {
    return 'Une erreur est survenue. Réessayez.';
  }

  if (status == 400) return 'Demande invalide. Vérifiez vos informations.';
  if (status == 401) return 'Session expirée. Veuillez vous reconnecter.';
  if (status == 403) return "Accès refusé. Vous n'avez pas l'autorisation.";
  if (status == 404) return "Contenu introuvable. Réessayez plus tard.";
  if (status == 409) return 'Conflit détecté. Réessayez.';
  if (status == 422) return 'Données invalides. Vérifiez vos informations.';
  if (status == 429) return 'Trop de tentatives. Réessayez dans quelques instants.';
  if (status >= 500) return 'Le serveur rencontre un problème. Réessayez plus tard.';

  return 'Une erreur est survenue. Réessayez.';
}

String? _extractServerMessage(dynamic data) {
  if (data == null) return null;

  if (data is String) {
    final s = data.trim();
    if (s.isEmpty) return null;
    try {
      final decoded = json.decode(s);
      return _extractServerMessage(decoded);
    } catch (_) {
      return s;
    }
  }

  if (data is Map) {
    final message = data['message'];
    if (message is String) return message.trim();

    final error = data['error'];
    if (error is String) return error.trim();

    final detail = data['detail'];
    if (detail is String) return detail.trim();

    return null;
  }

  if (data is List) {
    for (final item in data) {
      final msg = _extractServerMessage(item);
      if (msg != null && msg.isNotEmpty) return msg;
    }
  }

  return null;
}

