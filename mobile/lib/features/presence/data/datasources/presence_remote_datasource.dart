import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

class PresenceRemoteDataSource {
  final Dio dio;

  PresenceRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> creerAppel(String groupeId) async {
    final response = await dio.post(
      ApiEndpoints.creerAppelPresence(),
      data: {'groupeId': groupeId},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getAppel(String appelId) async {
    final response = await dio.get(
      ApiEndpoints.getAppelPresence(appelId),
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> marquerPresence({
    required String confirmationId,
    required String statut,
    String? note,
  }) async {
    final response = await dio.put(
      ApiEndpoints.marquerPresence(confirmationId),
      data: {
        'statut': statut,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> marquerPresenceBulk({
    required String appelId,
    required List<Map<String, dynamic>> confirmations,
  }) async {
    final response = await dio.post(
      ApiEndpoints.marquerPresenceBulk(appelId),
      data: {'confirmations': confirmations},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> scanPresenceByQr({
    required String appelId,
    required String codeUnique,
  }) async {
    final response = await dio.post(
      ApiEndpoints.scanPresenceQr(appelId),
      data: {'codeUnique': codeUnique},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> cloturerAppel(String appelId) async {
    final response = await dio.post(
      ApiEndpoints.cloturerAppel(appelId),
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> reinitialiserAbsents(String appelId) async {
    final response = await dio.post(
      ApiEndpoints.reinitialiserAbsents(appelId),
    );
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getHistorique(String groupeId) async {
    final response = await dio.get(
      ApiEndpoints.getHistoriqueAppels(groupeId),
    );
    final data = response.data['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> getStatsPelerin(String pelerinId) async {
    final response = await dio.get(
      ApiEndpoints.getStatsPelerin(pelerinId),
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>?> getPelerinAppelActif() async {
    final response = await dio.get(ApiEndpoints.mobilePelerinPresenceActive);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>> getPelerinAppelById(String appelId) async {
    final response = await dio.get(
      ApiEndpoints.mobilePelerinPresenceAppel(appelId),
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> confirmerPresencePelerin({
    required String confirmationId,
  }) async {
    final response = await dio.put(
      ApiEndpoints.mobilePelerinPresenceConfirmation(confirmationId),
      data: const <String, dynamic>{},
    );
    return response.data['data'];
  }
}
