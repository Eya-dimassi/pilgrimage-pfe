import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../services/notification_feed_refresh_service.dart';
import '../data/mobile_notifications_repository.dart';
import '../domain/mobile_notification.dart';

final notificationFeedRefreshProvider =
    ChangeNotifierProvider<NotificationFeedRefreshService>((ref) {
  return NotificationFeedRefreshService.instance;
});

final mobileNotificationsProvider =
    FutureProvider<MobileNotificationFeed>((ref) async {
  ref.watch(notificationFeedRefreshProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    return const MobileNotificationFeed.empty();
  }

  final repository = ref.watch(mobileNotificationsRepositoryProvider);
  return repository.fetchNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final feed = ref.watch(mobileNotificationsProvider).valueOrNull;
  return feed?.unreadCount ?? 0;
});
