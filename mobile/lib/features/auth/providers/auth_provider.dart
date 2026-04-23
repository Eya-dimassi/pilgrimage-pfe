import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../services/fcm_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_requests.dart';
import '../domain/auth_session.dart';

final authProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final storage = ref.read(secureStorageProvider);
    final savedSession = await storage.readSession();
    if (savedSession == null) {
      return null;
    }

    try {
      final repository = ref.read(authRepositoryProvider);
      final currentUser = await repository.getMe();
      final hydratedSession = savedSession.copyWith(
        user: savedSession.user.copyWith(
          id: currentUser.id,
          email: currentUser.email,
          role: currentUser.role,
          nom: currentUser.nom,
          prenom: currentUser.prenom,
          telephone: currentUser.telephone,
          agenceId: currentUser.agenceId ?? savedSession.user.agenceId,
          lienParente: currentUser.lienParente ?? savedSession.user.lienParente,
          codeUnique: currentUser.codeUnique ?? savedSession.user.codeUnique,
          dateNaissance:
              currentUser.dateNaissance ?? savedSession.user.dateNaissance,
          nationalite: currentUser.nationalite ?? savedSession.user.nationalite,
          numeroPasseport:
              currentUser.numeroPasseport ?? savedSession.user.numeroPasseport,
          photoUrl: currentUser.photoUrl ?? savedSession.user.photoUrl,
          specialite: currentUser.specialite ?? savedSession.user.specialite,
          groupeNom: currentUser.groupeNom ?? savedSession.user.groupeNom,
        ),
      );

      if (!_isAllowedMobileRole(hydratedSession.user.role)) {
        await storage.clearSession();
        return null;
      }

      await storage.saveSession(hydratedSession);
      await FCMService().syncTokenIfLoggedIn();
      return hydratedSession;
    } catch (_) {
      await storage.clearSession();
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);
    final request = LoginRequest.fromRaw(
      email: email,
      password: password,
    );

    try {
      final session = await repository.login(
        email: request.email,
        password: request.password,
      );

      if (!_isAllowedMobileRole(session.user.role)) {
        throw const AuthException(
          'Ce portail mobile est reserve aux pelerins, guides et familles',
        );
      }

      await storage.saveSession(session);
      final currentUser = await repository.getMe();
      final hydratedSession = session.copyWith(
        user: session.user.copyWith(
          id: currentUser.id,
          email: currentUser.email,
          role: currentUser.role,
          nom: currentUser.nom,
          prenom: currentUser.prenom,
          telephone: currentUser.telephone,
          agenceId: currentUser.agenceId ?? session.user.agenceId,
          lienParente: currentUser.lienParente ?? session.user.lienParente,
          codeUnique: currentUser.codeUnique ?? session.user.codeUnique,
          dateNaissance:
              currentUser.dateNaissance ?? session.user.dateNaissance,
          nationalite: currentUser.nationalite ?? session.user.nationalite,
          numeroPasseport:
              currentUser.numeroPasseport ?? session.user.numeroPasseport,
          photoUrl: currentUser.photoUrl ?? session.user.photoUrl,
          specialite: currentUser.specialite ?? session.user.specialite,
          groupeNom: currentUser.groupeNom ?? session.user.groupeNom,
        ),
      );

      await storage.saveSession(hydratedSession);
      await FCMService().syncTokenIfLoggedIn();
      state = AsyncData(hydratedSession);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Une erreur est survenue');
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);
    final refreshToken = state.valueOrNull?.refreshToken;

    state = const AsyncLoading();

    try {
      await FCMService().unregisterCurrentDevice();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await repository.logout(refreshToken);
      }
    } catch (_) {
      // The local session should still be cleared even if the API call fails.
    } finally {
      await storage.clearSession();
      state = const AsyncData(null);
    }
  }

  Future<void> expireSession() async {
    final storage = ref.read(secureStorageProvider);
    await storage.clearSession();
    state = const AsyncData(null);
  }

  Future<String> forgotPassword(String email) async {
    final repository = ref.read(authRepositoryProvider);
    final request = ForgotPasswordRequest.fromRaw(email);
    return repository.forgotPassword(request.email);
  }

  Future<String> familySignup({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String codeUnique,
    String? telephone,
    String? lienParente,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final request = FamilySignupRequest.fromRaw(
      nom: nom,
      prenom: prenom,
      email: email,
      password: password,
      codeUnique: codeUnique,
      telephone: telephone,
      lienParente: lienParente ?? 'Autre',
    );

    return repository.familySignup(
      nom: request.nom,
      prenom: request.prenom,
      email: request.email,
      password: request.password,
      codeUnique: request.codeUnique,
      telephone: request.telephone,
      lienParente: request.lienParente,
    );
  }

  Future<String> addFamilyLink({
    required String codeUnique,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final normalizedCode = codeUnique.trim();

    if (normalizedCode.isEmpty) {
      throw const AuthException('Veuillez entrer le code unique du pelerin');
    }

    return repository.addFamilyLink(codeUnique: normalizedCode);
  }

  Future<void> refreshProfile() async {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);

    final currentUser = await repository.getMe();
    final updatedSession = session.copyWith(
      user: session.user.copyWith(
        id: currentUser.id,
        email: currentUser.email,
        role: currentUser.role,
        nom: currentUser.nom,
        prenom: currentUser.prenom,
        telephone: currentUser.telephone,
        agenceId: currentUser.agenceId ?? session.user.agenceId,
        lienParente: currentUser.lienParente ?? session.user.lienParente,
        codeUnique: currentUser.codeUnique ?? session.user.codeUnique,
        dateNaissance:
            currentUser.dateNaissance ?? session.user.dateNaissance,
        nationalite: currentUser.nationalite ?? session.user.nationalite,
        numeroPasseport:
            currentUser.numeroPasseport ?? session.user.numeroPasseport,
        photoUrl: currentUser.photoUrl ?? session.user.photoUrl,
        specialite: currentUser.specialite ?? session.user.specialite,
        groupeNom: currentUser.groupeNom ?? session.user.groupeNom,
      ),
    );

    await storage.saveSession(updatedSession);
    state = AsyncData(updatedSession);
  }

  Future<void> updateProfile({
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
  }) async {
    final session = state.valueOrNull;
    if (session == null) {
      throw const AuthException('Session introuvable');
    }

    final repository = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);
    final request = ProfileUpdateRequest.fromRaw(
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      lienParente: lienParente,
      specialite: specialite,
      dateNaissance: dateNaissance,
      nationalite: nationalite,
      numeroPasseport: numeroPasseport,
      photoUrl: photoUrl,
    );

    final updatedUser = await repository.updateMe(
      nom: request.nom,
      prenom: request.prenom,
      email: request.email,
      telephone: request.telephone,
      lienParente: request.lienParente,
      specialite: request.specialite,
      dateNaissance: request.dateNaissance,
      nationalite: request.nationalite,
      numeroPasseport: request.numeroPasseport,
      photoUrl: request.photoUrl,
    );

    final updatedSession = session.copyWith(user: updatedUser);
    await storage.saveSession(updatedSession);
    state = AsyncData(updatedSession);
  }

  bool _isAllowedMobileRole(String role) {
    return role == 'PELERIN' || role == 'GUIDE' || role == 'FAMILLE';
  }
}
