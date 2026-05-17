class FamilyLink {
  const FamilyLink({
    required this.id,
    required this.pelerinId,
    required this.codeUnique,
    required this.nom,
    required this.prenom,
    this.groupe,
    this.linkedAt,
  });

  final String id;
  final String pelerinId;
  final String codeUnique;
  final String nom;
  final String prenom;
  final FamilyLinkedGroup? groupe;
  final DateTime? linkedAt;

  String get fullName => [prenom.trim(), nom.trim()]
      .where((part) => part.isNotEmpty)
      .join(' ')
      .trim();

  factory FamilyLink.fromJson(Map<String, dynamic> json) {
    return FamilyLink(
      id: json['id'] as String? ?? '',
      pelerinId: json['pelerinId'] as String? ?? '',
      codeUnique: json['codeUnique'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      linkedAt: json['linkedAt'] is String
          ? DateTime.tryParse(json['linkedAt'] as String)
          : null,
      groupe: json['groupe'] is Map<String, dynamic>
          ? FamilyLinkedGroup.fromJson(json['groupe'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FamilyLinkedGroup {
  const FamilyLinkedGroup({
    required this.id,
    required this.nom,
    required this.typeVoyage,
    required this.annee,
    this.dateDepart,
    this.dateRetour,
  });

  final String id;
  final String nom;
  final String typeVoyage;
  final int annee;
  final DateTime? dateDepart;
  final DateTime? dateRetour;

  factory FamilyLinkedGroup.fromJson(Map<String, dynamic> json) {
    return FamilyLinkedGroup(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      typeVoyage: json['typeVoyage'] as String? ?? '',
      annee: json['annee'] as int? ?? 0,
      dateDepart: json['dateDepart'] is String
          ? DateTime.tryParse(json['dateDepart'] as String)
          : null,
      dateRetour: json['dateRetour'] is String
          ? DateTime.tryParse(json['dateRetour'] as String)
          : null,
    );
  }
}
