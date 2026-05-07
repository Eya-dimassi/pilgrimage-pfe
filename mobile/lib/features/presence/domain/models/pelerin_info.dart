class PelerinInfo {
  const PelerinInfo({
    required this.id,
    required this.utilisateur,
  });

  final String id;
  final UtilisateurInfo utilisateur;

  factory PelerinInfo.fromJson(Map<String, dynamic> json) {
    return PelerinInfo(
      id: json['id'] as String? ?? '',
      utilisateur: UtilisateurInfo.fromJson(
        (json['utilisateur'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  String get nomComplet => '${utilisateur.prenom} ${utilisateur.nom}'.trim();

  String get initiales {
    final prenom = utilisateur.prenom.trim();
    final nom = utilisateur.nom.trim();
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    final value = '$p$n'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }
}

class UtilisateurInfo {
  const UtilisateurInfo({
    required this.nom,
    required this.prenom,
    this.photoUrl,
  });

  final String nom;
  final String prenom;
  final String? photoUrl;

  factory UtilisateurInfo.fromJson(Map<String, dynamic> json) {
    return UtilisateurInfo(
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
