import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_local_datasource.dart';
import '../datasources/assistant_remote_datasource.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final AssistantRemoteDataSource remoteDataSource;
  final AssistantLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AssistantRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AssistantMessageEntity>> query({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final result = await remoteDataSource.query(
            text: text,
            contextEntityType: contextEntityType,
            contextEntityId: contextEntityId,
            conversationSessionId: conversationSessionId,
          );
          return Right(result);
        } catch (e) {
          // Fallback to local offline engine if server encounters issue
          final localResult = await localDataSource.queryOffline(
            text: text,
            contextEntityType: contextEntityType,
            contextEntityId: contextEntityId,
          );
          return Right(localResult);
        }
      } else {
        final localResult = await localDataSource.queryOffline(
          text: text,
          contextEntityType: contextEntityType,
          contextEntityId: contextEntityId,
        );
        return Right(localResult);
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSuggestedQuestions({
    String? contextEntityType,
    String? contextEntityId,
  }) async {
    try {
      final suggestions = localDataSource.getSuggestedQuestions(
        contextEntityType: contextEntityType,
        contextEntityId: contextEntityId,
      );
      return Right(suggestions);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
