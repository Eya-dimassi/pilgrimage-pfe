class PelerinPresenceCall {
  const PelerinPresenceCall({
    required this.appel,
    required this.confirmation,
    required this.canConfirm,
  });

  final PelerinPresenceAppel appel;
  final PelerinPresenceConfirmation confirmation;
  final bool canConfirm;

  factory PelerinPresenceCall.fromJson(Map<String, dynamic> json) {
    return PelerinPresenceCall(
      appel: PelerinPresenceAppel.fromJson(
        (json['appel'] as Map<String, dynamic>?) ?? {},
      ),
      confirmation: PelerinPresenceConfirmation.fromJson(
        (json['confirmation'] as Map<String, dynamic>?) ?? {},
      ),
      canConfirm: json['canConfirm'] as bool? ?? false,
    );
  }
}

class PelerinPresenceAppel {
  const PelerinPresenceAppel({
    required this.id,
    required this.date,
    required this.statut,
    this.clotureAt,
    required this.groupe,
    required this.guide,
  });

  final String id;
  final DateTime date;
  final String statut;
  final DateTime? clotureAt;
  final PelerinPresenceGroupe groupe;
  final PelerinPresenceGuide guide;

  factory PelerinPresenceAppel.fromJson(Map<String, dynamic> json) {
    return PelerinPresenceAppel(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      statut: json['statut'] as String? ?? 'EN_COURS',
      clotureAt: json['clotureAt'] is String
          ? DateTime.tryParse(json['clotureAt'] as String)
          : null,
      groupe: PelerinPresenceGroupe.fromJson(
        (json['groupe'] as Map<String, dynamic>?) ?? {},
      ),
      guide: PelerinPresenceGuide.fromJson(
        (json['guide'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class PelerinPresenceGroupe {
  const PelerinPresenceGroupe({
    required this.id,
    required this.nom,
  });

  final String id;
  final String nom;

  factory PelerinPresenceGroupe.fromJson(Map<String, dynamic> json) {
    return PelerinPresenceGroupe(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
    );
  }
}

class PelerinPresenceGuide {
  const PelerinPresenceGuide({
    required this.id,
    required this.nom,
    required this.prenom,
  });

  final String id;
  final String nom;
  final String prenom;

  String get fullName => '$prenom $nom'.trim();

  factory PelerinPresenceGuide.fromJson(Map<String, dynamic> json) {
    return PelerinPresenceGuide(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
    );
  }
}

class PelerinPresenceConfirmation {
  const PelerinPresenceConfirmation({
    required this.id,
    required this.statut,
    this.confirmeAt,
    this.confirmeMode,
    this.note,
  });

  final String id;
  final String statut;
  final DateTime? confirmeAt;
  final String? confirmeMode;
  final String? note;

  bool get isPresent => statut == 'PRESENT';
  bool get isEnAttente => statut == 'EN_ATTENTE';

  factory PelerinPresenceConfirmation.fromJson(Map<String, dynamic> json) {
    return PelerinPresenceConfirmation(
      id: json['id'] as String? ?? '',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      confirmeAt: json['confirmeAt'] is String
          ? DateTime.tryParse(json['confirmeAt'] as String)
          : null,
      confirmeMode: json['confirmeMode'] as String?,
      note: json['note'] as String?,
    );
  }
}
