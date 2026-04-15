import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';
import 'famille_parcours.dart';

class FamilleParcoursPelerinsSheet extends ConsumerStatefulWidget {
  const FamilleParcoursPelerinsSheet({super.key});

  @override
  ConsumerState<FamilleParcoursPelerinsSheet> createState() =>
      _FamilleParcoursPelerinsSheetState();
}

class _FamilleParcoursPelerinsSheetState
    extends ConsumerState<FamilleParcoursPelerinsSheet> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<FamillePelerinItem> _items = const [];

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
      final response = await dio.get('/famille/pelerins');
      final raw = response.data;
      final list = raw is List ? raw : const [];
      setState(() {
        _items = list
            .whereType<Map>()
            .map((e) => FamillePelerinItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      });
    } on DioException catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } catch (error) {
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSearch() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom du pèlerin',
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Effacer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openParcours(FamillePelerinItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FamilleParcoursPelerinSheet(
        pelerinId: item.pelerinId,
        pelerinNom: item.pelerinNom,
      ),
    );
  }

  String _formatVoyage(String? typeVoyage) {
    switch (typeVoyage) {
      case 'HAJJ':
        return 'Hajj';
      case 'UMRAH':
        return 'Umrah';
      default:
        return typeVoyage ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    final query = _searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? _items
        : _items
            .where((p) => p.pelerinNom.toLowerCase().contains(query))
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
                            const SizedBox(height: 14),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mes pèlerins',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Suivi de progression',
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.2,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: _openSearch,
                                    icon: const Icon(Icons.search_rounded),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (visible.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _EmptyState(isSearch: query.isNotEmpty),
                              )
                            else
                              ...visible.map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: InkWell(
                                    onTap: () => _openParcours(item),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.card.withValues(alpha: 0.96),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: AppColors.borderSoft,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.pelerinNom,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.groupeNom == null
                                                ? 'Groupe: -'
                                                : 'Groupe: ${item.groupeNom}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.35,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Type: ${_formatVoyage(item.typeVoyage)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.35,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Voir le parcours →',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.blue
                                                  .withValues(alpha: 0.95),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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

class FamillePelerinItem {
  FamillePelerinItem({
    required this.pelerinId,
    required this.pelerinNom,
    required this.groupeId,
    required this.groupeNom,
    required this.typeVoyage,
    required this.etapeActuelle,
  });

  final String pelerinId;
  final String pelerinNom;
  final String? groupeId;
  final String? groupeNom;
  final String? typeVoyage;
  final String? etapeActuelle;

  factory FamillePelerinItem.fromJson(Map<String, dynamic> json) {
    return FamillePelerinItem(
      pelerinId: (json['pelerinId'] as String?) ?? '',
      pelerinNom: (json['pelerinNom'] as String?) ?? '',
      groupeId: json['groupeId'] as String?,
      groupeNom: json['groupeNom'] as String?,
      typeVoyage: json['typeVoyage'] as String?,
      etapeActuelle: json['etapeActuelle'] as String?,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isSearch
            ? 'Aucun pèlerin ne correspond à la recherche.'
            : "Aucun pèlerin n'est suivi par ce compte.",
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        const Icon(
          Icons.warning_amber_rounded,
          size: 30,
          color: AppColors.gold,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async => onRetry(),
            child: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }
}
