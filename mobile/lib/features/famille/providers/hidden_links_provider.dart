import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kHiddenLinksKey = 'famille_hidden_link_ids';

final hiddenLinkIdsProvider =
    AsyncNotifierProvider<HiddenLinksNotifier, Set<String>>(
  HiddenLinksNotifier.new,
);

class HiddenLinksNotifier extends AsyncNotifier<Set<String>> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<Set<String>> build() async {
    try {
      final raw = await _storage.read(key: _kHiddenLinksKey);
      if (raw == null) return <String>{};
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> hide(String linkId) async {
    final current = state.valueOrNull ?? <String>{};
    final updated = <String>{...current, linkId};
    state = AsyncData(updated);
    await _storage.write(key: _kHiddenLinksKey, value: jsonEncode(updated.toList()));
  }

  Future<void> restore(String linkId) async {
    final current = state.valueOrNull ?? <String>{};
    final updated = <String>{...current}..remove(linkId);
    state = AsyncData(updated);
    await _storage.write(key: _kHiddenLinksKey, value: jsonEncode(updated.toList()));
  }
}
