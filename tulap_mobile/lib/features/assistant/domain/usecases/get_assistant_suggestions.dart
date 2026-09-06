import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantSuggestions {
  final AssistantRepository repository;

  GetAssistantSuggestions(this.repository);

  Future<Either<Failure, List<String>>> call({
    String? contextEntityType,
    String? contextEntityId,
  }) {
    return repository.getSuggestedQuestions(
      contextEntityType: contextEntityType,
      contextEntityId: contextEntityId,
    );
  }
}
