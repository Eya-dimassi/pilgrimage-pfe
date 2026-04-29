import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/sos_alert.dart';

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SosRepository(dio);
});

class SosRepository {
  const SosRepository(this._dio);

  final Dio _dio;

  Future<SosAlert?> fetchMyActiveSos() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.mobileSosMe);
      final activeAlert = response.data?['activeAlert'];
      if (activeAlert is! Map<String, dynamic>) {
        return null;
      }
      return SosAlert.fromJson(activeAlert);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<SosAlert> triggerSos({
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.mobileSos,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );

      final alert = response.data?['alert'];
      if (alert is! Map<String, dynamic>) {
        throw const AuthException('Reponse SOS invalide');
      }

      return SosAlert.fromJson(alert);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}
