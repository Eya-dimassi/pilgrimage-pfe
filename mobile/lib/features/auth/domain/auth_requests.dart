import 'auth_exception.dart';

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  factory LoginRequest.fromRaw({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw const AuthException('Email et mot de passe requis');
    }

    return LoginRequest(
      email: normalizedEmail,
      password: normalizedPassword,
    );
  }
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({
    required this.email,
  });

  final String email;

  factory ForgotPasswordRequest.fromRaw(String email) {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      throw const AuthException('Veuillez entrer votre email');
    }

    return ForgotPasswordRequest(email: normalizedEmail);
  }
}

class FamilySignupRequest {
  const FamilySignupRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.codeUnique,
    required this.lienParente,
    this.telephone,
  });

  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String codeUnique;
  final String lienParente;
  final String? telephone;

  factory FamilySignupRequest.fromRaw({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String codeUnique,
    required String lienParente,
    String? telephone,
  }) {
    final normalizedNom = nom.trim();
    final normalizedPrenom = prenom.trim();
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();
    final normalizedCode = codeUnique.trim();
    final normalizedPhone = telephone?.trim();

    if (normalizedNom.isEmpty ||
        normalizedPrenom.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedCode.isEmpty ||
        normalizedPassword.isEmpty) {
      throw const AuthException('Veuillez remplir les champs requis');
    }

    if (normalizedPassword.length < 8) {
      throw const AuthException(
        'Le mot de passe doit contenir au moins 8 caracteres',
      );
    }

    return FamilySignupRequest(
      nom: normalizedNom,
      prenom: normalizedPrenom,
      email: normalizedEmail,
      password: normalizedPassword,
      codeUnique: normalizedCode,
      lienParente: lienParente,
      telephone: normalizedPhone != null && normalizedPhone.isNotEmpty
          ? normalizedPhone
          : null,
    );
  }
}

class ProfileUpdateRequest {
  const ProfileUpdateRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.lienParente,
    this.specialite,
    this.dateNaissance,
    this.nationalite,
    this.numeroPasseport,
    this.photoUrl,
  });

  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? lienParente;
  final String? specialite;
  final DateTime? dateNaissance;
  final String? nationalite;
  final String? numeroPasseport;
  final String? photoUrl;

  factory ProfileUpdateRequest.fromRaw({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    String? lienParente,
    String? specialite,
    DateTime? dateNaissance,
    String? nationalite,
    String? numeroPasseport,
    String? photoUrl,
  }) {
    final normalizedNom = nom.trim();
    final normalizedPrenom = prenom.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = telephone?.trim();
    final normalizedLienParente = lienParente?.trim();
    final normalizedSpecialite = specialite?.trim();
    final normalizedNationalite = nationalite?.trim();
    final normalizedNumeroPasseport = numeroPasseport?.trim();
    final normalizedPhotoUrl = photoUrl?.trim();

    if (normalizedNom.isEmpty ||
        normalizedPrenom.isEmpty ||
        normalizedEmail.isEmpty) {
      throw const AuthException('Veuillez remplir les champs requis');
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      throw const AuthException('Veuillez entrer un email valide');
    }

    return ProfileUpdateRequest(
      nom: normalizedNom,
      prenom: normalizedPrenom,
      email: normalizedEmail,
      telephone: normalizedPhone != null && normalizedPhone.isNotEmpty
          ? normalizedPhone
          : null,
      lienParente: normalizedLienParente != null &&
              normalizedLienParente.isNotEmpty
          ? normalizedLienParente
          : null,
      specialite: normalizedSpecialite != null && normalizedSpecialite.isNotEmpty
          ? normalizedSpecialite
          : null,
      dateNaissance: dateNaissance,
      nationalite:
          normalizedNationalite != null && normalizedNationalite.isNotEmpty
              ? normalizedNationalite
              : null,
      numeroPasseport: normalizedNumeroPasseport != null &&
              normalizedNumeroPasseport.isNotEmpty
          ? normalizedNumeroPasseport
          : null,
      photoUrl: normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty
          ? normalizedPhotoUrl
          : null,
    );
  }
}
