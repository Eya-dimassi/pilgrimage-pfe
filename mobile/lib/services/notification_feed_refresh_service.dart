import 'package:flutter/foundation.dart';

class NotificationFeedRefreshService extends ChangeNotifier {
  NotificationFeedRefreshService._();

  static final NotificationFeedRefreshService instance =
      NotificationFeedRefreshService._();

  void bump() {
    notifyListeners();
  }
}
