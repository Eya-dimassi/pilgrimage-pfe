import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../../famille/domain/family_link.dart';
import '../../famille/domain/family_presence_status.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': email,
          'motDePasse': password,
        },
      );

      return AuthSession.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return AuthUser.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<AuthUser> updateMe({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    String? lienParente,
    String? specialite,
    String? disponibilite,
    DateTime? dateNaissance,
    String? nationalite,
    String? numeroPasseport,
    String? photoUrl,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.updateMe,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'lienParente': lienParente,
          'specialite': specialite,
          'disponibilite': disponibilite,
          'dateNaissance': dateNaissance?.toIso8601String(),
          'nationalite': nationalite,
          'numeroPasseport': numeroPasseport,
          'photoUrl': photoUrl,
        },
      );

      return AuthUser.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      return response.data?['message'] as String? ??
          'Si cet email existe, un lien de reinitialisation a ete envoye';
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<String> familySignup({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String codeUnique,
    String? telephone,
    String? lienParente,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.familySignup,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motDePasse': password,
          'telephone': telephone,
          'lienParente': lienParente,
          'codeUnique': codeUnique,
        },
      );

      return _localizedFamilyMessage(
        response.data?['message'] as String?,
        fallbackKey: 'family_signup.success',
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<String> addFamilyLink({
    required String codeUnique,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.familyLinks,
        data: {
          'codeUnique': codeUnique,
        },
      );

      return _localizedFamilyMessage(
        response.data?['message'] as String?,
        fallbackKey: 'family_home.add_relative_sheet.success',
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<List<FamilyLink>> fetchFamilyLinks() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.familyLinks);
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FamilyLink.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<List<FamilyPresenceStatus>> fetchFamilyPresenceStatuses() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mobileFamilyPresenceStatuses,
      );
      final raw = response.data?['data'];
      if (raw is! List) {
        return const <FamilyPresenceStatus>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(FamilyPresenceStatus.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}

String _localizedFamilyMessage(String? message, {required String fallbackKey}) {
  final normalized = message?.trim();
  switch (normalized) {
    case 'Compte famille cree avec succes':
    case 'Compte famille cree avec succes. Vous pouvez maintenant vous connecter.':
      return 'family_signup.success'.tr();
    case 'Proche ajoute avec succes':
      return 'family_home.add_relative_sheet.success'.tr();
  }
  return normalized?.isNotEmpty == true ? normalized! : fallbackKey.tr();
}
