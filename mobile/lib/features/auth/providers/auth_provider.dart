import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_exception.dart';
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
          agenceId: currentUser.agenceId ?? savedSession.user.agenceId,
        ),
      );

      if (!_isAllowedMobileRole(hydratedSession.user.role)) {
        await storage.clearSession();
        return null;
      }

      await storage.saveSession(hydratedSession);
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
    try {
      final session = await repository.login(email: email, password: password);

      if (!_isAllowedMobileRole(session.user.role)) {
        throw const AuthException(
          'Ce portail mobile est reserve aux pelerins, guides et familles',
        );
      }

      await storage.saveSession(session);
      state = AsyncData(session);
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

  Future<String> forgotPassword(String email) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.forgotPassword(email);
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
        agenceId: currentUser.agenceId ?? session.user.agenceId,
      ),
    );

    await storage.saveSession(updatedSession);
    state = AsyncData(updatedSession);
  }

  bool _isAllowedMobileRole(String role) {
    return role == 'PELERIN' || role == 'GUIDE' || role == 'FAMILLE';
  }
}
