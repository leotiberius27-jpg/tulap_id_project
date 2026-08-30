import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_archive_repository.dart';

class RebuildSearchIndex {
  final SearchArchiveRepository repository;

  RebuildSearchIndex(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.rebuildSearchIndex();
  }
}
