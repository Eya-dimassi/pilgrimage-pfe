class FamilyLink {
  const FamilyLink({
    required this.id,
    required this.pelerinId,
    required this.codeUnique,
    required this.nom,
    required this.prenom,
    this.groupe,
  });

  final String id;
  final String pelerinId;
  final String codeUnique;
  final String nom;
  final String prenom;
  final FamilyLinkedGroup? groupe;

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
  });

  final String id;
  final String nom;
  final String typeVoyage;
  final int annee;

  factory FamilyLinkedGroup.fromJson(Map<String, dynamic> json) {
    return FamilyLinkedGroup(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      typeVoyage: json['typeVoyage'] as String? ?? '',
      annee: json['annee'] as int? ?? 0,
    );
  }
}
