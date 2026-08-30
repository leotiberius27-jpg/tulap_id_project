import '../entities/supporting_document_entity.dart';
import '../repositories/travel_repository.dart';

class AddSupportingDocument {
  final TravelRepository _repository;

  AddSupportingDocument(this._repository);

  Future<SupportingDocumentEntity> call(SupportingDocumentEntity doc) {
    return _repository.addSupportingDocument(doc);
  }
}
