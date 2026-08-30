import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_archive_repository.dart';

class SaveRecentSearch {
  final SearchArchiveRepository repository;

  SaveRecentSearch(this.repository);

  Future<Either<Failure, void>> call(String query) {
    return repository.saveRecentSearch(query);
  }
}
