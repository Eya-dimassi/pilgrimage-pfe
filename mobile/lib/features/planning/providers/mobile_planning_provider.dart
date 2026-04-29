import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mobile_planning_repository.dart';
import '../domain/mobile_planning_models.dart';

final mobilePlanningGroupsProvider =
    FutureProvider<List<MobilePlanningGroup>>((ref) async {
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchGroups();
    });

final mobilePlanningDetailProvider =
    FutureProvider.family<MobilePlanningData, String>((ref, groupeId) async {
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchGroupPlanning(groupeId);
    });

final mobilePlanningGroupHistoryProvider =
    FutureProvider<List<MobilePlanningGroupHistoryItem>>((ref) async {
      final repository = ref.watch(mobilePlanningRepositoryProvider);
      return repository.fetchPelerinGroupHistory();
    });
