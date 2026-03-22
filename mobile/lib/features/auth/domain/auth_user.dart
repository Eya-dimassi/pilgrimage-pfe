class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.nom,
    required this.prenom,
    this.agenceId,
  });

  final String id;
  final String email;
  final String role;
  final String nom;
  final String prenom;
  final String? agenceId;

  AuthUser copyWith({
    String? id,
    String? email,
    String? role,
    String? nom,
    String? prenom,
    String? agenceId,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      agenceId: agenceId ?? this.agenceId,
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
      agenceId: json['agenceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'nom': nom,
      'prenom': prenom,
      'agenceId': agenceId,
    };
  }
}
