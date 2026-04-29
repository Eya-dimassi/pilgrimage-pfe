import 'package:flutter/foundation.dart';

class PlanningFeedRefreshService extends ChangeNotifier {
  PlanningFeedRefreshService._();

  static final PlanningFeedRefreshService instance =
      PlanningFeedRefreshService._();

  void bump() {
    notifyListeners();
  }
}
