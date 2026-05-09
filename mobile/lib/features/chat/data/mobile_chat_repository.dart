import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

final mobileChatRepositoryProvider = Provider<MobileChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MobileChatRepository(dio);
});

class MobileChatRepository {
  MobileChatRepository(this._dio);

  final Dio _dio;

  Future<String> sendMessage({
    required String message,
    required List<MobileChatMessagePayload> history,
    required String language,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.mobileChatMessage,
      data: {
        'message': message,
        'history': history.map((item) => item.toJson()).toList(),
        'language': language,
      },
    );

    final answer = response.data?['answer'] as String?;
    if (answer == null || answer.trim().isEmpty) {
      throw Exception('Reponse indisponible');
    }

    return answer.trim();
  }
}

class MobileChatMessagePayload {
  const MobileChatMessagePayload({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}
