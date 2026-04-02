class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.agenceId,
    this.lienParente,
    this.codeUnique,
    this.dateNaissance,
    this.nationalite,
    this.numeroPasseport,
    this.photoUrl,
    this.specialite,
    this.groupeNom,
  });

  final String id;
  final String email;
  final String role;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? agenceId;
  final String? lienParente;
  final String? codeUnique;
  final DateTime? dateNaissance;
  final String? nationalite;
  final String? numeroPasseport;
  final String? photoUrl;
  final String? specialite;
  final String? groupeNom;

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    String? nom,
    String? prenom,
    String? telephone,
    String? agenceId,
    String? lienParente,
    String? codeUnique,
    DateTime? dateNaissance,
    String? nationalite,
    String? numeroPasseport,
    String? photoUrl,
    String? specialite,
    String? groupeNom,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      agenceId: agenceId ?? this.agenceId,
      lienParente: lienParente ?? this.lienParente,
      codeUnique: codeUnique ?? this.codeUnique,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      nationalite: nationalite ?? this.nationalite,
      numeroPasseport: numeroPasseport ?? this.numeroPasseport,
      photoUrl: photoUrl ?? this.photoUrl,
      specialite: specialite ?? this.specialite,
      groupeNom: groupeNom ?? this.groupeNom,
    );
  }

  String get fullName {
    final parts = [prenom.trim(), nom.trim()].where((part) => part.isNotEmpty);
    return parts.join(' ').trim();
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String?,
      agenceId: json['agenceId'] as String?,
      lienParente: json['lienParente'] as String?,
      codeUnique: json['codeUnique'] as String?,
      dateNaissance: json['dateNaissance'] is String
          ? DateTime.tryParse(json['dateNaissance'] as String)
          : null,
      nationalite: json['nationalite'] as String?,
      numeroPasseport: json['numeroPasseport'] as String?,
      photoUrl: json['photoUrl'] as String?,
      specialite: json['specialite'] as String?,
      groupeNom: json['groupeNom'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'agenceId': agenceId,
      'lienParente': lienParente,
      'codeUnique': codeUnique,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'nationalite': nationalite,
      'numeroPasseport': numeroPasseport,
      'photoUrl': photoUrl,
      'specialite': specialite,
      'groupeNom': groupeNom,
    };
  }
}
