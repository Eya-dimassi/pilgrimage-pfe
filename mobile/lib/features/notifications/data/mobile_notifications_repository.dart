import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/mobile_notification.dart';

final mobileNotificationsRepositoryProvider =
    Provider<MobileNotificationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MobileNotificationsRepository(dio);
});

class MobileNotificationsRepository {
  const MobileNotificationsRepository(this._dio);

  final Dio _dio;

  Future<MobileNotificationFeed> fetchNotifications() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.mobileNotifications);
      return MobileNotificationFeed.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch<void>(ApiEndpoints.mobileNotificationRead(notificationId));
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.post<void>(ApiEndpoints.mobileNotificationsReadAll);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}
