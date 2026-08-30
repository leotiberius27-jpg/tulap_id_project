import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_archive_repository.dart';

class GetAvailableYears {
  final SearchArchiveRepository repository;

  GetAvailableYears(this.repository);

  Future<Either<Failure, List<int>>> call() {
    return repository.getAvailableYears();
  }
}
