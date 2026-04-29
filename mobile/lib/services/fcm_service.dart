import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_endpoints.dart';
import '../core/storage/secure_storage.dart';
import '../firebase_options.dart';
import 'local_notifications_service.dart';
import 'notification_feed_refresh_service.dart';
import 'notification_navigation_service.dart';
import 'planning_feed_refresh_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FCMService {
  factory FCMService() => _instance;

  FCMService._internal();

  static final FCMService _instance = FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SecureStorageService _storage =
      const SecureStorageService(FlutterSecureStorage());
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerTokenWithBackend(token);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await _registerTokenWithBackend(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      NotificationFeedRefreshService.instance.bump();
      if (_shouldRefreshPlanning(message.data)) {
        PlanningFeedRefreshService.instance.bump();
      }
      showFCMNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _openMessage(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _openMessage(initialMessage);
    }

    _initialized = true;
  }

  Future<void> syncTokenIfLoggedIn() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerTokenWithBackend(token);
  }

  Future<void> unregisterCurrentDevice() async {
    final accessToken = await _storage.readAccessToken();
    final token = await _messaging.getToken();

    if (accessToken == null || accessToken.isEmpty || token == null || token.isEmpty) {
      return;
    }

    try {
      await _dio.delete<void>(
        ApiEndpoints.mobileNotificationToken,
        data: {'token': token},
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
        ),
      );
    } catch (_) {
      // Local logout should still continue if backend cleanup fails.
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    final accessToken = await _storage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      await _dio.post<void>(
        ApiEndpoints.mobileNotificationToken,
        data: {
          'token': token,
          'platform': _platformLabel,
        },
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to register FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openMessage(RemoteMessage message) async {
    NotificationFeedRefreshService.instance.bump();
    if (_shouldRefreshPlanning(message.data)) {
      PlanningFeedRefreshService.instance.bump();
    }
    final session = await _storage.readSession();
    final role = session?.user.role ?? 'PELERIN';
    NotificationNavigationService.openFromPayload(message.data, role: role);
  }

  bool _shouldRefreshPlanning(Map<String, dynamic> payload) {
    final type = payload['type']?.toString().trim().toLowerCase();
    final tab = payload['tab']?.toString().trim().toLowerCase();

    if (payload['groupeId'] != null ||
        payload['eventId'] != null ||
        payload['etape'] != null) {
      return true;
    }

    return type == 'planning_update' ||
        type == 'upcoming_rendezvous' ||
        type == 'planning' ||
        tab == 'planning';
  }

  String get _platformLabel {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isMacOS) return 'MACOS';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isLinux) return 'LINUX';
    return 'UNKNOWN';
  }
}
