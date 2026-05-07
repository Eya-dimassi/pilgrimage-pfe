import 'confirmation_presence.dart';
import 'presence_stats.dart';

class AppelPresence {
  const AppelPresence({
    required this.id,
    required this.groupeId,
    required this.guideId,
    required this.date,
    required this.statut,
    this.clotureAt,
    required this.groupe,
    required this.confirmations,
  });

  final String id;
  final String groupeId;
  final String guideId;
  final DateTime date;
  final String statut; // EN_COURS, CLOTURE
  final DateTime? clotureAt;
  final GroupeInfo groupe;
  final List<ConfirmationPresence> confirmations;

  factory AppelPresence.fromJson(Map<String, dynamic> json) {
    final rawConfirmations = json['confirmations'];
    final confirmations = rawConfirmations is List
        ? rawConfirmations
            .whereType<Map<String, dynamic>>()
            .map(ConfirmationPresence.fromJson)
            .toList()
        : <ConfirmationPresence>[];

    return AppelPresence(
      id: json['id'] as String? ?? '',
      groupeId: json['groupeId'] as String? ?? '',
      guideId: json['guideId'] as String? ?? '',
      date: json['date'] is String
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      statut: json['statut'] as String? ?? 'EN_COURS',
      clotureAt: json['clotureAt'] is String
          ? DateTime.tryParse(json['clotureAt'] as String)
          : null,
      groupe: GroupeInfo.fromJson((json['groupe'] as Map<String, dynamic>?) ?? {}),
      confirmations: confirmations,
    );
  }
}

class GroupeInfo {
  const GroupeInfo({
    required this.id,
    required this.nom,
  });

  final String id;
  final String nom;

  factory GroupeInfo.fromJson(Map<String, dynamic> json) {
    return GroupeInfo(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
    );
  }
}

class AppelPresenceData {
  const AppelPresenceData({
    required this.appel,
    required this.stats,
  });

  final AppelPresence appel;
  final PresenceStats stats;

  factory AppelPresenceData.fromJson(Map<String, dynamic> json) {
    return AppelPresenceData(
      appel: AppelPresence.fromJson((json['appel'] as Map<String, dynamic>?) ?? {}),
      stats: PresenceStats.fromJson((json['stats'] as Map<String, dynamic>?) ?? {}),
    );
  }
}
