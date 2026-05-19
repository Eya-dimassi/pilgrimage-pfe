import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

String apiErrorMessage(DioException error) {
  // Network / transport errors (no HTTP status)
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'api_error_message.timeout'.tr();
    case DioExceptionType.connectionError:
      return 'api_error_message.connection_error'.tr();
    case DioExceptionType.badCertificate:
      return 'api_error_message.bad_certificate'.tr();
    case DioExceptionType.cancel:
      return 'api_error_message.cancel'.tr();
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
      return 'api_error_message.unauthorized'.tr();
    }
    if (status == 403) {
      return 'api_error_message.forbidden'.tr();
    }
    return serverMessage;
  }

  if (status == null) {
    return 'api_error_message.unknown'.tr();
  }

  if (status == 400) return 'api_error_message.bad_request'.tr();
  if (status == 401) return 'api_error_message.unauthorized'.tr();
  if (status == 403) return 'api_error_message.forbidden'.tr();
  if (status == 404) return 'api_error_message.not_found'.tr();
  if (status == 409) return 'api_error_message.conflict'.tr();
  if (status == 422) return 'api_error_message.unprocessable_entity'.tr();
  if (status == 429) return 'api_error_message.too_many_requests'.tr();
  if (status >= 500) return 'api_error_message.server_error'.tr();

  return 'api_error_message.unknown'.tr();
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

