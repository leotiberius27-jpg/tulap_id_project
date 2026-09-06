import '../../../../core/network/dio_client.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../models/assistant_response_model.dart';

abstract class AssistantRemoteDataSource {
  Future<AssistantMessageEntity> query({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  });
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  final DioClient dioClient;

  AssistantRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AssistantMessageEntity> query({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  }) async {
    final response = await dioClient.dio.post(
      '/assistant/query',
      data: {
        'query': text,
        if (contextEntityType != null) 'contextEntityType': contextEntityType,
        if (contextEntityId != null) 'contextEntityId': contextEntityId,
        if (conversationSessionId != null)
          'conversationSessionId': conversationSessionId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return AssistantResponseModel.fromJson(data);
  }
}
