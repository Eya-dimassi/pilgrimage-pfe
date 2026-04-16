class MobilePlanningGroup {
  const MobilePlanningGroup({
    required this.id,
    required this.nom,
    required this.annee,
    required this.typeVoyage,
    this.dateDepart,
    this.dateRetour,
    this.status,
  });

  final String id;
  final String nom;
  final int annee;
  final String typeVoyage;
  final DateTime? dateDepart;
  final DateTime? dateRetour;
  final String? status;

  factory MobilePlanningGroup.fromJson(Map<String, dynamic> json) {
    return MobilePlanningGroup(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      annee: json['annee'] as int? ?? 0,
      typeVoyage: json['typeVoyage'] as String? ?? '',
      dateDepart: json['dateDepart'] is String
          ? DateTime.tryParse(json['dateDepart'] as String)
          : null,
      dateRetour: json['dateRetour'] is String
          ? DateTime.tryParse(json['dateRetour'] as String)
          : null,
      status: json['status'] as String?,
    );
  }
}

class MobilePlanningEvent {
  const MobilePlanningEvent({
    required this.id,
    required this.type,
    required this.titre,
    this.description,
    this.lieu,
    this.heureDebutPrevue,
  });

  final String id;
  final String type;
  final String titre;
  final String? description;
  final String? lieu;
  final DateTime? heureDebutPrevue;

  List<String> get lieux {
    if (lieu == null || lieu!.trim().isEmpty) return const [];
    return lieu!
        .split(RegExp(r'\s*(?:â€¢|•)\s*'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory MobilePlanningEvent.fromJson(Map<String, dynamic> json) {
    return MobilePlanningEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      lieu: json['lieu'] as String?,
      heureDebutPrevue: json['heureDebutPrevue'] is String
          ? DateTime.tryParse(json['heureDebutPrevue'] as String)
          : null,
    );
  }
}

class MobilePlanningDay {
  const MobilePlanningDay({
    required this.id,
    required this.date,
    this.titre,
    required this.evenements,
  });

  final String id;
  final DateTime date;
  final String? titre;
  final List<MobilePlanningEvent> evenements;

  factory MobilePlanningDay.fromJson(Map<String, dynamic> json) {
    return MobilePlanningDay(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      titre: json['titre'] as String?,
      evenements: ((json['evenements'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningEvent.fromJson)
          .toList(),
    );
  }
}

class MobilePlanningData {
  const MobilePlanningData({
    required this.groupe,
    required this.plannings,
  });

  final MobilePlanningGroup groupe;
  final List<MobilePlanningDay> plannings;

  factory MobilePlanningData.fromJson(Map<String, dynamic> json) {
    return MobilePlanningData(
      groupe: MobilePlanningGroup.fromJson(
        json['groupe'] as Map<String, dynamic>? ?? const {},
      ),
      plannings: ((json['plannings'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningDay.fromJson)
          .toList(),
    );
  }
}
