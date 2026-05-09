import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/family_link.dart';

final familyLinksProvider = FutureProvider<List<FamilyLink>>((ref) async {
  ref.watch(authProvider.select((state) => state.valueOrNull?.user.id));
  final repository = ref.watch(authRepositoryProvider);
  return repository.fetchFamilyLinks();
});
