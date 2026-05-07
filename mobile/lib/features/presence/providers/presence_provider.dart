import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/presence_remote_datasource.dart';
import '../data/presence_repository.dart';
import '../domain/models/appel_presence.dart';
import '../domain/models/pelerin_presence_call.dart';

// ============================================
// DATA SOURCE
// ============================================

final presenceRemoteDataSourceProvider = Provider<PresenceRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PresenceRemoteDataSource(dio: dio);
});

// ============================================
// REPOSITORY
// ============================================

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  final remoteDataSource = ref.watch(presenceRemoteDataSourceProvider);
  return PresenceRepository(remoteDataSource: remoteDataSource);
});

// ============================================
// PROVIDERS - APPEL PRÉSENCE
// ============================================

/// Provider pour un appel de présence spécifique
final appelPresenceProvider =
    FutureProvider.family<AppelPresenceData, String>((ref, appelId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getAppel(appelId);
});

/// Provider pour l'historique des appels d'un groupe
final historiqueAppelsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, groupeId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getHistorique(groupeId);
});

/// Provider pour les stats d'un pèlerin
final statsPelerinProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, pelerinId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getStatsPelerin(pelerinId);
});

// ============================================
// STATE PROVIDERS
// ============================================

/// Provider pour l'état de création d'un appel
final creationAppelStateProvider =
    StateProvider<AsyncValue<Map<String, dynamic>>>((ref) {
  return const AsyncValue.data({});
});

/// Provider pour l'état de sauvegarde
final savingPresenceStateProvider = StateProvider<bool>((ref) => false);

/// Provider pour les modifications locales (statuts)
final localStatutsProvider =
    StateProvider.autoDispose<Map<String, String>>((ref) => {});

/// Provider pour les notes locales
final localNotesProvider =
    StateProvider.autoDispose<Map<String, String?>>((ref) => {});

/// Appel actif cote pelerin
final pelerinPresenceActiveProvider =
    FutureProvider<PelerinPresenceCall?>((ref) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return repository.getPelerinAppelActif();
});

/// Appel presence pelerin par id
final pelerinPresenceByIdProvider =
    FutureProvider.family<PelerinPresenceCall, String>((ref, appelId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return repository.getPelerinAppelById(appelId);
});
