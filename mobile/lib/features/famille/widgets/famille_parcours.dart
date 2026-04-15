import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';

class FamilleParcoursPelerinSheet extends ConsumerStatefulWidget {
  const FamilleParcoursPelerinSheet({
    super.key,
    required this.pelerinId,
    required this.pelerinNom,
  });

  final String pelerinId;
  final String pelerinNom;

  @override
  ConsumerState<FamilleParcoursPelerinSheet> createState() =>
      _FamilleParcoursPelerinSheetState();
}

class _FamilleParcoursPelerinSheetState
    extends ConsumerState<FamilleParcoursPelerinSheet> {
  bool _loading = true;
  String? _error;
  FamilleParcoursResponse? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = ref.read(dioProvider);
    try {
      final response =
          await dio.get('/famille/pelerins/${widget.pelerinId}/parcours');
      setState(() {
        _data = FamilleParcoursResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      });
    } on DioException catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } catch (error) {
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatVoyage(String typeVoyage) {
    switch (typeVoyage) {
      case 'HAJJ':
        return 'Hajj';
      case 'UMRAH':
        return 'Umrah';
      default:
        return typeVoyage;
    }
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} à ${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

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
                    : _data == null
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: _ErrorView(
                              message: 'Parcours introuvable.',
                              onRetry: _load,
                            ),
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
                                        icon: const Icon(Icons.arrow_back_rounded),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.pelerinNom,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: _SummaryCard(
                                    groupeNom: _data!.groupeNom,
                                    typeVoyage: _data!.typeVoyage,
                                    progression: _data!.progression,
                                    formatVoyage: _formatVoyage,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ..._data!.etapes.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final step = entry.value;

                                  final currentIndex = _data!.etapeActuelle ==
                                          null
                                      ? -1
                                      : _data!.etapes.indexWhere(
                                          (e) => e.code == _data!.etapeActuelle,
                                        );
                                  final nextIndex = currentIndex + 1;
                                  final displayStatus =
                                      (step.statut == 'A_VENIR' &&
                                              index == nextIndex)
                                          ? 'PROCHAINE'
                                          : step.statut;

                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      14,
                                    ),
                                    child: _TimelineTile(
                                      step: step,
                                      statutOverride: displayStatus,
                                      isLast:
                                          index == _data!.etapes.length - 1,
                                      formatDateTime: _formatDateTime,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}

class FamilleParcoursResponse {
  FamilleParcoursResponse({
    required this.groupeNom,
    required this.typeVoyage,
    required this.etapeActuelle,
    required this.progression,
    required this.etapes,
  });

  final String groupeNom;
  final String typeVoyage;
  final String? etapeActuelle;
  final ParcoursProgression progression;
  final List<ParcoursEtape> etapes;

  factory FamilleParcoursResponse.fromJson(Map<String, dynamic> json) {
    final progressionJson =
        (json['progression'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final etapesJson = (json['etapes'] as List?) ?? const [];

    return FamilleParcoursResponse(
      groupeNom: (json['groupeNom'] as String?) ?? '',
      typeVoyage: (json['typeVoyage'] as String?) ?? '',
      etapeActuelle: json['etapeActuelle'] as String?,
      progression: ParcoursProgression.fromJson(progressionJson),
      etapes: etapesJson
          .whereType<Map>()
          .map((e) => ParcoursEtape.fromJson(e.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => a.ordre.compareTo(b.ordre)),
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

class ParcoursEtape {
  ParcoursEtape({
    required this.code,
    required this.ordre,
    required this.nom,
    required this.nomArabe,
    required this.description,
    required this.dureeEstimee,
    required this.lieu,
    required this.statut,
    required this.valideeAt,
    required this.valideePar,
    required this.note,
  });

  final String code;
  final int ordre;
  final String nom;
  final String nomArabe;
  final String description;
  final int dureeEstimee;
  final String lieu;
  final String statut;
  final DateTime? valideeAt;
  final String? valideePar;
  final String? note;

  factory ParcoursEtape.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ParcoursEtape(
      code: (json['code'] as String?) ?? '',
      ordre: asInt(json['ordre']),
      nom: (json['nom'] as String?) ?? '',
      nomArabe: (json['nomArabe'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      dureeEstimee: asInt(json['dureeEstimee']),
      lieu: (json['lieu'] as String?) ?? '',
      statut: (json['statut'] as String?) ?? '',
      valideeAt: parseDate(json['valideeAt']),
      valideePar: json['valideePar'] as String?,
      note: json['note'] as String?,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.groupeNom,
    required this.typeVoyage,
    required this.progression,
    required this.formatVoyage,
  });

  final String groupeNom;
  final String typeVoyage;
  final ParcoursProgression progression;
  final String Function(String) formatVoyage;

  @override
  Widget build(BuildContext context) {
    final percent = progression.pourcentage.clamp(0, 100);
    final progressValue = percent / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatVoyage(typeVoyage)} - $groupeNom',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              color: AppColors.blue,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${progression.etapesValidees}/${progression.total} étapes validées',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.statutOverride,
    required this.isLast,
    required this.formatDateTime,
  });

  final ParcoursEtape step;
  final String statutOverride;
  final bool isLast;
  final String Function(DateTime) formatDateTime;

  Color get _tone {
    switch (statutOverride) {
      case 'VALIDEE':
        return AppColors.green;
      case 'EN_COURS':
        return AppColors.blue;
      case 'PROCHAINE':
        return AppColors.gold;
      default:
        return AppColors.textFaint;
    }
  }

  String get _label {
    switch (statutOverride) {
      case 'VALIDEE':
        return 'VALIDÉE';
      case 'EN_COURS':
        return 'EN COURS';
      case 'PROCHAINE':
        return 'PROCHAINE';
      default:
        return 'À VENIR';
    }
  }

  IconData get _icon {
    switch (statutOverride) {
      case 'VALIDEE':
        return Icons.check_rounded;
      case 'EN_COURS':
        return Icons.radio_button_checked_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: statutOverride == 'VALIDEE' ? _tone : Colors.white,
                  border: Border.all(color: _tone, width: 2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _icon,
                  size: 14,
                  color: statutOverride == 'VALIDEE' ? Colors.white : _tone,
                ),
              ),
              const SizedBox(height: 2),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '[${step.ordre}] ${step.nom} (${step.nomArabe})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(label: _label, color: _tone),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (step.description.isNotEmpty)
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        text: '~${step.dureeEstimee}h',
                      ),
                      _MetaPill(
                        icon: Icons.place_outlined,
                        text: step.lieu,
                      ),
                    ],
                  ),
                  if (step.valideeAt != null) ...[
                    const SizedBox(height: 10),
                    _MetaLine(
                      icon: Icons.verified_rounded,
                      text: 'Validée le ${formatDateTime(step.valideeAt!)}',
                      color: AppColors.green,
                    ),
                    if (step.valideePar != null &&
                        step.valideePar!.trim().isNotEmpty)
                      _MetaLine(
                        icon: Icons.person_outline_rounded,
                        text: 'Par ${step.valideePar}',
                        color: AppColors.textMuted,
                      ),
                    if (step.note != null && step.note!.trim().isNotEmpty)
                      _MetaLine(
                        icon: Icons.sticky_note_2_outlined,
                        text: step.note!,
                        color: AppColors.textMuted,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: color,
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
