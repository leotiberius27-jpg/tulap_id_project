import 'package:flutter/foundation.dart';
import '../../domain/entities/supporting_document_entity.dart';
import '../../domain/usecases/add_supporting_document.dart';
import '../../domain/usecases/generate_lpj_package.dart';
import '../../domain/usecases/get_travel_mission_detail.dart';
import '../../domain/repositories/travel_repository.dart';

class TravelMissionDetailState {
  final bool isLoading;
  final TravelMissionDetailBundle? bundle;
  final String? errorMessage;
  final bool isGeneratingLpj;
  final String? successMessage;

  const TravelMissionDetailState({
    this.isLoading = false,
    this.bundle,
    this.errorMessage,
    this.isGeneratingLpj = false,
    this.successMessage,
  });

  TravelMissionDetailState copyWith({
    bool? isLoading,
    TravelMissionDetailBundle? bundle,
    String? errorMessage,
    bool? isGeneratingLpj,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TravelMissionDetailState(
      isLoading: isLoading ?? this.isLoading,
      bundle: bundle ?? this.bundle,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isGeneratingLpj: isGeneratingLpj ?? this.isGeneratingLpj,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TravelMissionDetailController extends ChangeNotifier {
  final GetTravelMissionDetail _getTravelMissionDetail;
  final AddSupportingDocument _addSupportingDocument;
  final GenerateLpjPackage _generateLpjPackage;
  final TravelRepository _repository;

  TravelMissionDetailState _state = const TravelMissionDetailState();
  TravelMissionDetailState get state => _state;

  TravelMissionDetailController({
    required GetTravelMissionDetail getTravelMissionDetail,
    required AddSupportingDocument addSupportingDocument,
    required GenerateLpjPackage generateLpjPackage,
    required TravelRepository repository,
  })  : _getTravelMissionDetail = getTravelMissionDetail,
        _addSupportingDocument = addSupportingDocument,
        _generateLpjPackage = generateLpjPackage,
        _repository = repository;

  Future<void> loadDetail(String travelId) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final bundle = await _getTravelMissionDetail(travelId);
      _state = _state.copyWith(isLoading: false, bundle: bundle);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat detail perjalanan dinas: $e',
      );
    }
    notifyListeners();
  }

  Future<void> markCompleted(String travelId) async {
    try {
      await _repository.completeTravelMission(travelId);
      await loadDetail(travelId);
      _state = _state.copyWith(successMessage: 'Perjalanan dinas berhasil diselesaikan.');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Gagal mengubah status: $e');
      notifyListeners();
    }
  }

  Future<void> addDocument(SupportingDocumentEntity doc) async {
    try {
      await _addSupportingDocument(doc);
      await loadDetail(doc.travelMissionId);
      _state = _state.copyWith(successMessage: 'Dokumen pendukung berhasil dilampirkan.');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Gagal melampirkan dokumen: $e');
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String docId, String travelId) async {
    try {
      await _repository.deleteSupportingDocument(docId);
      await loadDetail(travelId);
      _state = _state.copyWith(successMessage: 'Dokumen berhasil dihapus.');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Gagal menghapus dokumen: $e');
      notifyListeners();
    }
  }

  Future<void> generateLpj() async {
    final bundle = _state.bundle;
    if (bundle == null) return;

    _state = _state.copyWith(isGeneratingLpj: true, clearError: true);
    notifyListeners();

    try {
      final pkg = await _generateLpjPackage(
        travel: bundle.travel,
        linkedTasks: bundle.linkedTasks,
        expenseSummary: bundle.expenseSummary,
        photos: bundle.photos,
        supportingDocs: bundle.supportingDocuments,
        completeness: bundle.completeness,
      );

      await loadDetail(bundle.travel.id);
      _state = _state.copyWith(
        isGeneratingLpj: false,
        successMessage: 'Paket LPJ (${pkg.packageCode} ${pkg.versionLabel}) berhasil dibuat!',
      );
    } catch (e) {
      _state = _state.copyWith(
        isGeneratingLpj: false,
        errorMessage: 'Gagal membuat paket LPJ: $e',
      );
    }
    notifyListeners();
  }
}
