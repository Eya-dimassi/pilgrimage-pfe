import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_feed_refresh_service.dart';
import 'notification_navigation_service.dart';
import 'planning_feed_refresh_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.high,
);

Future<void> initLocalNotifications() async {
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;

      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          NotificationFeedRefreshService.instance.bump();
          if (_shouldRefreshPlanning(decoded)) {
            PlanningFeedRefreshService.instance.bump();
          }
          final role = decoded['role']?.toString() ?? 'PELERIN';
          NotificationNavigationService.openFromPayload(decoded, role: role);
        }
      } catch (_) {
        // Ignore malformed notification payloads.
      }
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void showFCMNotification(RemoteMessage message) {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString();
  final body = notification?.body ?? message.data['body']?.toString();

  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  final payload = Map<String, dynamic>.from(message.data);
  payload.putIfAbsent('role', () => payload['role']?.toString() ?? 'PELERIN');

  flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(payload),
  );
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
