import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/mobile_notifications_provider.dart';
import '../data/guide_sos_repository.dart';
import '../domain/guide_sos_alert.dart';

final guideSosProvider = FutureProvider<List<GuideSosAlert>>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || session.user.role != 'GUIDE') {
    return const [];
  }

  final repository = ref.watch(guideSosRepositoryProvider);
  return repository.fetchActiveSos();
});

final guideSosActionsProvider =
    Provider<GuideSosActionsController>((ref) => GuideSosActionsController(ref));

class GuideSosActionsController {
  GuideSosActionsController(this.ref);

  final Ref ref;

  Future<void> resolve(String sosId) async {
    final repository = ref.read(guideSosRepositoryProvider);
    await repository.resolveSos(sosId);
    ref.invalidate(guideSosProvider);
    ref.invalidate(mobileNotificationsProvider);
  }
}
