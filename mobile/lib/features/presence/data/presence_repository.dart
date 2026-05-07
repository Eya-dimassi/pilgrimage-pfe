import 'package:dio/dio.dart';
import '../domain/models/appel_presence.dart';
import '../domain/exceptions/presence_exception.dart';
import '../domain/models/pelerin_presence_call.dart';
import 'datasources/presence_remote_datasource.dart';

class PresenceRepository {
  final PresenceRemoteDataSource remoteDataSource;

  PresenceRepository({required this.remoteDataSource});

  /// Créer un appel de présence
  Future<Map<String, dynamic>> creerAppel(String groupeId) async {
    try {
      return await remoteDataSource.creerAppel(groupeId);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Récupérer un appel de présence
  Future<AppelPresenceData> getAppel(String appelId) async {
    try {
      final data = await remoteDataSource.getAppel(appelId);
      return AppelPresenceData.fromJson(data);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Marquer une présence individuelle
  Future<Map<String, dynamic>> marquerPresence({
    required String confirmationId,
    required String statut,
    String? note,
  }) async {
    try {
      return await remoteDataSource.marquerPresence(
        confirmationId: confirmationId,
        statut: statut,
        note: note,
      );
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Marquer plusieurs présences en masse
  Future<Map<String, dynamic>> marquerPresenceBulk({
    required String appelId,
    required List<Map<String, dynamic>> confirmations,
  }) async {
    try {
      return await remoteDataSource.marquerPresenceBulk(
        appelId: appelId,
        confirmations: confirmations,
      );
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Clôturer un appel
  Future<Map<String, dynamic>> cloturerAppel(String appelId) async {
    try {
      return await remoteDataSource.cloturerAppel(appelId);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Historique des appels
  Future<List<Map<String, dynamic>>> getHistorique(String groupeId) async {
    try {
      return await remoteDataSource.getHistorique(groupeId);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Stats pèlerin
  Future<Map<String, dynamic>> getStatsPelerin(String pelerinId) async {
    try {
      return await remoteDataSource.getStatsPelerin(pelerinId);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Appel actif pour le pelerin connecte
  Future<PelerinPresenceCall?> getPelerinAppelActif() async {
    try {
      final data = await remoteDataSource.getPelerinAppelActif();
      if (data == null) return null;
      return PelerinPresenceCall.fromJson(data);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Recuperer un appel pelerin par id
  Future<PelerinPresenceCall> getPelerinAppelById(String appelId) async {
    try {
      final data = await remoteDataSource.getPelerinAppelById(appelId);
      return PelerinPresenceCall.fromJson(data);
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }

  /// Confirmer sa presence (Je suis present)
  Future<Map<String, dynamic>> confirmerPresencePelerin({
    required String confirmationId,
    String? note,
  }) async {
    try {
      return await remoteDataSource.confirmerPresencePelerin(
        confirmationId: confirmationId,
        note: note,
      );
    } on DioException catch (e) {
      throw PresenceException.fromDio(e);
    }
  }
}
