import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';

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

      return response.data?['message'] as String? ??
          'Compte famille cree avec succes';
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}
