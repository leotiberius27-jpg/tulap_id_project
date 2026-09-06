import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/assistant_message_entity.dart';
import '../repositories/assistant_repository.dart';

class AskAssistant {
  final AssistantRepository repository;

  AskAssistant(this.repository);

  Future<Either<Failure, AssistantMessageEntity>> call({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  }) {
    return repository.query(
      text: text,
      contextEntityType: contextEntityType,
      contextEntityId: contextEntityId,
      conversationSessionId: conversationSessionId,
    );
  }
}
