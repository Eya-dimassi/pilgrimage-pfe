// ignore_for_file: unused_element

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';
import 'guide_groupe_pelerins_sheet.dart';

class GuideParcoursGroupsSheet extends ConsumerStatefulWidget {
  const GuideParcoursGroupsSheet({
    super.key,
    this.openPelerinsOnTap = false,
  });

  final bool openPelerinsOnTap;

  @override
  ConsumerState<GuideParcoursGroupsSheet> createState() =>
      _GuideParcoursGroupsSheetState();
}

class _GuideParcoursGroupsSheetState
    extends ConsumerState<GuideParcoursGroupsSheet> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<GuideGroupeItem> _groups = const [];
  _GroupFilter _filter = _GroupFilter.all;

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
      final response = await dio.get('/guide/groupes');
      final raw = response.data;
      final list = raw is List ? raw : const [];
      setState(() {
        _groups = list
            .whereType<Map>()
            .map((e) => GuideGroupeItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      });
    } on DioException catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } catch (error) {
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openGroupe(GuideGroupeItem group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          GuideGroupePelerinsSheet(groupeId: group.id, groupeNom: group.nom),
    );
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    final query = _searchController.text.trim().toLowerCase();

    final baseGroups = switch (_filter) {
      _GroupFilter.all => _groups,
      _GroupFilter.enCours =>
        _groups.where((g) => g.status == 'EN_COURS').toList(),
      _GroupFilter.planifie =>
        _groups.where((g) => g.status == 'PLANIFIE').toList(),
      _GroupFilter.termine => _groups
          .where(
            (g) => g.status == 'TERMINE' || g.progression.pourcentage >= 100,
          )
          .toList(),
    };

    final visibleGroups = query.isEmpty
        ? baseGroups
        : baseGroups.where((g) => g.nom.toLowerCase().contains(query)).toList();

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
                ? const _LoadingView()
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Groupes - Guide',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Consultez vos groupes et la liste des pelerins.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _SearchField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 10),
                                  _FilterRow(
                                    value: _filter,
                                    onChanged: (next) =>
                                        setState(() => _filter = next),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${visibleGroups.length} groupe(s)',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (visibleGroups.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _EmptyState(isSearch: query.isNotEmpty),
                              )
                            else
                              ...visibleGroups.map(
                                (group) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: _GroupCard(
                                    group: group,
                                    onOpen: () => _openGroupe(group),
                                    formatDate: _formatDate,
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

enum _GroupFilter {
  all,
  enCours,
  planifie,
  termine,
}

class GuideGroupeItem {
  GuideGroupeItem({
    required this.id,
    required this.nom,
    required this.typeVoyage,
    required this.status,
    required this.nbPelerins,
    required this.dateDepart,
    required this.progression,
    required this.etapeActuelleDetails,
  });

  final String id;
  final String nom;
  final String typeVoyage;
  final String status;
  final int nbPelerins;
  final DateTime? dateDepart;
  final ParcoursProgression progression;
  final EtapeDetails? etapeActuelleDetails;

  factory GuideGroupeItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return GuideGroupeItem(
      id: (json['id'] as String?) ?? '',
      nom: (json['nom'] as String?) ?? '',
      typeVoyage: (json['typeVoyage'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      nbPelerins: json['nbPelerins'] is int
          ? (json['nbPelerins'] as int)
          : int.tryParse('${json['nbPelerins']}') ?? 0,
      dateDepart: parseDate(json['dateDepart']),
      progression: ParcoursProgression.fromJson(
        (json['progression'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      etapeActuelleDetails: json['etapeActuelleDetails'] is Map
          ? EtapeDetails.fromJson(
              (json['etapeActuelleDetails'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class ParcoursProgression {
  ParcoursProgression({
    required this.etapesValidees,
    required this.total,
    required this.pourcentage,
  });

  final int etapesValidees;
  final int total;
  final int pourcentage;

  factory ParcoursProgression.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

    return ParcoursProgression(
      etapesValidees: asInt(json['etapesValidees']),
      total: asInt(json['total']),
      pourcentage: asInt(json['pourcentage']),
    );
  }
}

class EtapeDetails {
  EtapeDetails({
    required this.code,
    required this.ordre,
    required this.nom,
    required this.nomArabe,
  });

  final String code;
  final int ordre;
  final String nom;
  final String nomArabe;

  factory EtapeDetails.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

    return EtapeDetails(
      code: (json['code'] as String?) ?? '',
      ordre: asInt(json['ordre']),
      nom: (json['nom'] as String?) ?? '',
      nomArabe: (json['nomArabe'] as String?) ?? '',
    );
  }
}
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.formatDate,
  });

  final GuideGroupeItem group;
  final VoidCallback onOpen;
  final String Function(DateTime) formatDate;

  Color get _accentColor {
    if (group.status == 'EN_COURS') return AppColors.blue;
    if (group.status == 'PLANIFIE') return AppColors.gold;
    if (group.status == 'TERMINE') return AppColors.green;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final statusChip = _GroupStatusChip.fromStatus(
      status: group.status,
      percent: 0,
    );

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSoft, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bande colorée supérieure ──────────────────
            Container(height: 3, color: _accentColor),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ligne titre ───────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(typeVoyage: group.typeVoyage),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.nom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.dateDepart == null
                                  ? group.typeVoyage
                                  : '${group.typeVoyage} · Départ ${formatDate(group.dateDepart!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusChip,
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Touchez pour voir la liste des pelerins.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer pelerins ───────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSoft, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.group_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${group.nbPelerins} pelerins',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Voir la liste',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.blue.withValues(alpha: 0.9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type badge H / U ──────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.typeVoyage});
  final String typeVoyage;

  @override
  Widget build(BuildContext context) {
    final isHajj = typeVoyage == 'HAJJ';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isHajj
            ? const Color(0xFFE6F1FB)
            : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        isHajj ? 'H' : 'U',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isHajj
              ? const Color(0xFF0C447C)
              : const Color(0xFF633806),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.percent,
  });

  final String status;
  final int percent;

  @override
  Widget build(BuildContext context) {
    if (percent >= 100 || status == 'TERMINE') {
      return const Icon(Icons.check_circle_rounded, color: AppColors.green);
    }
    if (status == 'PLANIFIE') {
      return const Icon(Icons.assignment_rounded, color: AppColors.textMuted);
    }
    if (status == 'EN_COURS') {
      return const Icon(
        Icons.pause_circle_filled_rounded,
        color: AppColors.gold,
      );
    }
    return const Icon(Icons.info_outline_rounded, color: AppColors.textMuted);
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.groups_rounded,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSearch
                  ? 'Aucun groupe ne correspond à la recherche.'
                  : "Aucun groupe actif n'est pour le moment.",
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher un groupe',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.value,
    required this.onChanged,
  });

  final _GroupFilter value;
  final ValueChanged<_GroupFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(_GroupFilter v, String label) {
      final selected = value == v;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onChanged(v),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected ? AppColors.text : AppColors.textMuted,
        ),
        selectedColor: AppColors.section,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_GroupFilter.all, 'Tous'),
          const SizedBox(width: 8),
          chip(_GroupFilter.enCours, 'En cours'),
          const SizedBox(width: 8),
          chip(_GroupFilter.planifie, 'Planifiés'),
          const SizedBox(width: 8),
          chip(_GroupFilter.termine, 'Terminés'),
        ],
      ),
    );
  }
}

class _GroupStatusChip extends StatelessWidget {
  const _GroupStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  factory _GroupStatusChip.fromStatus({
    required String status,
    required int percent,
  }) {
    if (percent >= 100 || status == 'TERMINE') {
      return const _GroupStatusChip(label: 'TERMINÉ', color: AppColors.green);
    }
    if (status == 'EN_COURS') {
      return const _GroupStatusChip(label: 'EN COURS', color: AppColors.blue);
    }
    if (status == 'PLANIFIE') {
      return const _GroupStatusChip(
        label: 'PLANIFIÉ',
        color: AppColors.textMuted,
      );
    }
    return const _GroupStatusChip(label: 'INFO', color: AppColors.textMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      children: const [
        SizedBox(height: 10),
        Center(
          child: _Handle(),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _HeaderSkeleton(),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _GroupCardSkeleton(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _GroupCardSkeleton(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _GroupCardSkeleton(),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonBox(width: 160, height: 22, radius: 10),
        SizedBox(height: 8),
        _SkeletonBox(width: double.infinity, height: 14, radius: 8),
        SizedBox(height: 14),
        _SkeletonBox(width: double.infinity, height: 52, radius: 20),
      ],
    );
  }
}

class _GroupCardSkeleton extends StatelessWidget {
  const _GroupCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 34, height: 34, radius: 10),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 16)),
              SizedBox(width: 10),
              _SkeletonBox(width: 72, height: 26, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          _SkeletonBox(width: 220, height: 12),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 10, radius: 999),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          _SkeletonBox(width: 160, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderSoft),
      ),
    );
  }
}
