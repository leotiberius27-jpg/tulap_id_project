import 'package:flutter/foundation.dart';
import '../../../geotag_camera/domain/usecases/validate_location_integrity.dart';

enum LocationCheckStatus { checking, checked, error }

class LocationState {
  final LocationCheckStatus status;
  final LocationIntegrityStatus? integrityStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? errorMessage;

  const LocationState({
    this.status = LocationCheckStatus.checking,
    this.integrityStatus,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.errorMessage,
  });
}

/// LocationController
/// ----------------------------------------------------------------------
/// Data untuk layar Lokasi mandiri (Bagian 29 master prompt) - memakai
/// USECASE YANG SAMA dengan indikator GPS di kamera geotag
/// (ValidateLocationIntegrity), TIDAK ada logika deteksi baru.
///
/// SENGAJA hanya memeriksa lokasi SEKALI saat layar dibuka + saat user
/// menekan "Periksa Ulang" - BUKAN polling berkala seperti
/// GeotagCameraController. Prinsip privasi (Bagian 72): "Tidak ada
/// pelacakan berkelanjutan" - polling 3 detik di layar kamera itu
/// dibenarkan karena mempersiapkan capture bukti yang akan diambil detik
/// itu juga, sedangkan layar ini murni pengecekan sekali-lihat.
/// ----------------------------------------------------------------------
class LocationController extends ChangeNotifier {
  final ValidateLocationIntegrity _validateLocationIntegrity;

  LocationState _state = const LocationState();
  LocationState get state => _state;

  LocationController({
    required ValidateLocationIntegrity validateLocationIntegrity,
  }) : _validateLocationIntegrity = validateLocationIntegrity {
    checkLocation();
  }

  void _update(LocationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> checkLocation() async {
    _update(const LocationState(status: LocationCheckStatus.checking));

    final result = await _validateLocationIntegrity();

    result.fold(
      (failure) => _update(
        LocationState(
          status: LocationCheckStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (checkResult) => _update(
        LocationState(
          status: LocationCheckStatus.checked,
          integrityStatus: checkResult.status,
          latitude: checkResult.latitude,
          longitude: checkResult.longitude,
          accuracyMeters: checkResult.accuracyMeters,
        ),
      ),
    );
  }
}
