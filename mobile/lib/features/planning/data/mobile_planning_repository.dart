import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/mobile_planning_models.dart';

final mobilePlanningRepositoryProvider = Provider<MobilePlanningRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return MobilePlanningRepository(dio);
});

class MobilePlanningRepository {
  const MobilePlanningRepository(this._dio);

  final Dio _dio;

  Future<List<MobilePlanningGroup>> fetchGroups() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.mobilePlanningGroups);
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningGroup.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<List<MobilePlanningGroupHistoryItem>> fetchPelerinGroupHistory() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.mobilePlanningGroupsHistory,
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningGroupHistoryItem.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<MobilePlanningData> fetchGroupPlanning(String groupeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mobilePlanningGroup(groupeId),
      );
      return MobilePlanningData.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> validateEvent({
    required String groupeId,
    required String eventId,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.mobilePlanningValidateEvent(groupeId, eventId),
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}
