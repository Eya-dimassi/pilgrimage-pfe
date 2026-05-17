import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/family_presence_status.dart';

final familyPresenceStatusesProvider =
    FutureProvider<List<FamilyPresenceStatus>>((ref) async {
      ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
      final repository = ref.watch(authRepositoryProvider);
      return repository.fetchFamilyPresenceStatuses();
    });
