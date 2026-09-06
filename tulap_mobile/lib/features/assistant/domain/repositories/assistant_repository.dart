import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/assistant_message_entity.dart';

abstract class AssistantRepository {
  Future<Either<Failure, AssistantMessageEntity>> query({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  });

  Future<Either<Failure, List<String>>> getSuggestedQuestions({
    String? contextEntityType,
    String? contextEntityId,
  });
}
