import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../services/planning_feed_refresh_service.dart';
import '../data/mobile_planning_repository.dart';
import '../domain/mobile_planning_models.dart';

final planningFeedRefreshProvider =
    ChangeNotifierProvider<PlanningFeedRefreshService>((ref) {
  return PlanningFeedRefreshService.instance;
});

final mobilePlanningGroupsProvider =
    FutureProvider<List<MobilePlanningGroup>>((ref) async {
      ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
      ref.watch(planningFeedRefreshProvider);
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchGroups();
    });

final mobilePlanningDetailProvider =
    FutureProvider.family<MobilePlanningData, String>((ref, groupeId) async {
      ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
      ref.watch(planningFeedRefreshProvider);
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchGroupPlanning(groupeId);
    });

final mobilePlanningGroupHistoryProvider =
    FutureProvider<List<MobilePlanningGroupHistoryItem>>((ref) async {
      ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchPelerinGroupHistory();
    });
final mobilePlanningGroupPelerinsProvider =
    FutureProvider.family<List<MobileGroupPelerin>, String>((ref, groupeId) async {
      ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
      ref.watch(planningFeedRefreshProvider);
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchGroupPelerins(groupeId);
    });
