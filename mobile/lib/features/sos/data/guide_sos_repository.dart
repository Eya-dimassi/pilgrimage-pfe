import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/guide_sos_alert.dart';

final guideSosRepositoryProvider = Provider<GuideSosRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GuideSosRepository(dio);
});

class GuideSosRepository {
  const GuideSosRepository(this._dio);

  final Dio _dio;

  Future<List<GuideSosAlert>> fetchActiveSos() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.mobileGuideSos);
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GuideSosAlert.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> resolveSos(String sosId) async {
    try {
      await _dio.patch<void>(ApiEndpoints.mobileGuideSosResolve(sosId));
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}
