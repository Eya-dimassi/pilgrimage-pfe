import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/family_link.dart';

final familyLinksProvider = FutureProvider<List<FamilyLink>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.fetchFamilyLinks();
});
