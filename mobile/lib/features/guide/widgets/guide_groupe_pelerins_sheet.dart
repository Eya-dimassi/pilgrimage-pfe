import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

class GuideGroupePelerinsSheet extends ConsumerStatefulWidget {
  const GuideGroupePelerinsSheet({
    super.key,
    required this.groupeId,
    required this.groupeNom,
  });

  final String groupeId;
  final String groupeNom;

  @override
  ConsumerState<GuideGroupePelerinsSheet> createState() =>
      _GuideGroupePelerinsSheetState();
}

class _GuideGroupePelerinsSheetState
    extends ConsumerState<GuideGroupePelerinsSheet> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<GuidePelerinItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = ref.read(dioProvider);
    try {
      final response =
          await dio.get('/mobile/planning/groupes/${widget.groupeId}/pelerins');
      final raw = response.data;
      final list = raw is List ? raw : const [];
      setState(() {
        _items = list
            .whereType<Map>()
            .map((e) => GuidePelerinItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      });
    } on DioException catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue. Reessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = query.isEmpty
        ? _items
        : _items
            .where(
              (p) =>
                  p.fullName.toLowerCase().contains(query) ||
                  (p.telephone ?? '').toLowerCase().contains(query),
            )
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          child: SizedBox(
            height: height * 0.92,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.gold,
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: _ErrorView(message: _error!, onRetry: _load),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.gold,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.groupeNom,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    onPressed: _load,
                                    icon: const Icon(Icons.refresh_rounded),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pelerins',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${visibleItems.length} personne(s)',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search_rounded),
                                      hintText:
                                          'Rechercher par nom ou telephone',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (visibleItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: _EmptyState(),
                              )
                            else
                              ...visibleItems.map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: _PelerinCard(item: item),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

class GuidePelerinItem {
  GuidePelerinItem({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
  });

  final String id;
  final String nom;
  final String prenom;
  final String? telephone;

  String get fullName => '${prenom.trim()} ${nom.trim()}'.trim();

  factory GuidePelerinItem.fromJson(Map<String, dynamic> json) {
    return GuidePelerinItem(
      id: (json['id'] as String?) ?? '',
      nom: (json['nom'] as String?) ?? '',
      prenom: (json['prenom'] as String?) ?? '',
      telephone: json['telephone'] as String?,
    );
  }
}

class _PelerinCard extends StatelessWidget {
  const _PelerinCard({required this.item});

  final GuidePelerinItem item;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(item.prenom, item.nom);
    const tone = AppColors.blue;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSoft, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: tone.withValues(alpha: 0.14),
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: tone,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.telephone == null || item.telephone!.trim().isEmpty
                        ? '-'
                        : item.telephone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucun pelerin dans ce groupe pour le moment.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

String _initials(String prenom, String nom) {
  String first(String v) => v.trim().isEmpty ? '' : v.trim()[0].toUpperCase();
  final a = first(prenom);
  final b = first(nom);
  final s = (a + b).trim();
  return s.isEmpty ? '?' : s;
}
