import 'package:flutter/foundation.dart';
import '../../domain/entities/geotag_photo_entity.dart';
import '../../domain/usecases/capture_geotagged_photo.dart';
import '../../domain/usecases/validate_location_integrity.dart';

/// GeotagCameraViewState
/// ----------------------------------------------------------------------
/// State UI layar kamera. Dipisah dari GeotagPhotoEntity karena state
/// ini juga mengandung hal-hal khusus tampilan (status loading, error
/// message) yang tidak relevan untuk domain layer.
/// ----------------------------------------------------------------------
enum CaptureViewStatus { idle, capturing, previewing, error }

class GeotagCameraViewState {
  final LocationIntegrityStatus locationStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final CaptureViewStatus captureStatus;
  final GeotagPhotoEntity? lastCapturedPhoto;
  final String? errorMessage;

  const GeotagCameraViewState({
    this.locationStatus = LocationIntegrityStatus.checking,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.captureStatus = CaptureViewStatus.idle,
    this.lastCapturedPhoto,
    this.errorMessage,
  });

  /// Ambang akurasi "GPS terkunci" untuk mengaktifkan tombol jepret -
  /// LEBIH KETAT dari ambang 50m di MockLocationDetector (yang menandai
  /// lokasi valid/tidak-valid). Dua ambang ini sengaja terpisah: 50m
  /// adalah batas "lokasi bisa dipercaya sama sekali", 15m adalah batas
  /// "cukup presisi untuk bukti resmi" - fix asli GPS satelit biasanya
  /// bisa mencapai ini dalam beberapa detik di luar ruangan, sedangkan
  /// fix awal dari jaringan/WiFi jarang bisa.
  static const double gpsLockAccuracyMeters = 15.0;

  bool get isGpsLocked =>
      accuracyMeters != null && accuracyMeters! <= gpsLockAccuracyMeters;

  /// Tombol capture HANYA aktif jika lokasi valid (lolos pemeriksaan
  /// mock-location & root di ValidateLocationIntegrity - TIDAK diubah
  /// oleh penambahan ini), akurasi sudah cukup presisi ("terkunci"),
  /// dan tidak sedang memproses capture sebelumnya.
  bool get isCaptureEnabled =>
      locationStatus == LocationIntegrityStatus.valid &&
      isGpsLocked &&
      captureStatus != CaptureViewStatus.capturing;

  GeotagCameraViewState copyWith({
    LocationIntegrityStatus? locationStatus,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    CaptureViewStatus? captureStatus,
    GeotagPhotoEntity? lastCapturedPhoto,
    String? errorMessage,
  }) {
    return GeotagCameraViewState(
      locationStatus: locationStatus ?? this.locationStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      captureStatus: captureStatus ?? this.captureStatus,
      lastCapturedPhoto: lastCapturedPhoto ?? this.lastCapturedPhoto,
      errorMessage: errorMessage,
    );
  }
}

/// GeotagCameraController
/// ----------------------------------------------------------------------
/// Menghubungkan UI (GeotagCameraPage) dengan usecase domain. Memakai
/// ChangeNotifier sederhana - proyek ini bisa menggantinya dengan
/// Bloc/Riverpod sesuai preferensi tim tanpa mengubah usecase/domain.
///
/// Menjalankan pengecekan lokasi SECARA BERKALA (polling ringan setiap
/// beberapa detik) selama layar kamera terbuka, sesuai kebutuhan
/// indikator GPS real-time di top bar (Bagian 8 spesifikasi).
/// ----------------------------------------------------------------------
class GeotagCameraController extends ChangeNotifier {
  final ValidateLocationIntegrity _validateLocationIntegrity;
  final CaptureGeotaggedPhoto _captureGeotaggedPhoto;
  final String taskId;

  GeotagCameraViewState _state = const GeotagCameraViewState();
  GeotagCameraViewState get state => _state;

  bool _isDisposed = false;

  GeotagCameraController({
    required ValidateLocationIntegrity validateLocationIntegrity,
    required CaptureGeotaggedPhoto captureGeotaggedPhoto,
    required this.taskId,
  })  : _validateLocationIntegrity = validateLocationIntegrity,
        _captureGeotaggedPhoto = captureGeotaggedPhoto {
    _startLocationPolling();
  }

  void _updateState(GeotagCameraViewState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> _startLocationPolling() async {
    // Polling ringan tiap 3 detik - cukup responsif untuk UX tanpa
    // menguras baterai GPS secara berlebihan.
    while (!_isDisposed) {
      await _checkLocationOnce();
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _checkLocationOnce() async {
    _updateState(
      _state.copyWith(locationStatus: LocationIntegrityStatus.checking),
    );

    final result = await _validateLocationIntegrity();

    result.fold(
      (failure) => _updateState(
        _state.copyWith(
          locationStatus: LocationIntegrityStatus.invalid,
          errorMessage: failure.message,
        ),
      ),
      (checkResult) => _updateState(
        _state.copyWith(
          locationStatus: checkResult.status,
          latitude: checkResult.latitude,
          longitude: checkResult.longitude,
          accuracyMeters: checkResult.accuracyMeters,
          errorMessage: null,
        ),
      ),
    );
  }

  /// Dipanggil saat user menekan tombol capture besar. UI wajib
  /// mengecek `state.isCaptureEnabled` sebelum memanggil ini, namun
  /// method ini tetap melakukan guard clause sebagai lapis tambahan.
  Future<void> onCaptureButtonPressed() async {
    if (!_state.isCaptureEnabled) return;

    _updateState(_state.copyWith(captureStatus: CaptureViewStatus.capturing));

    final result = await _captureGeotaggedPhoto(taskId: taskId);

    result.fold(
      (failure) => _updateState(
        _state.copyWith(
          captureStatus: CaptureViewStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (photo) => _updateState(
        _state.copyWith(
          captureStatus: CaptureViewStatus.previewing,
          lastCapturedPhoto: photo,
        ),
      ),
    );
  }

  /// Dipanggil saat user menekan "Ambil Ulang" di layar preview -
  /// kembali ke mode live camera tanpa menyimpan foto sebelumnya
  /// sebagai bukti final (penghapusan file dilakukan di layer caller).
  void retakePhoto() {
    _updateState(
      _state.copyWith(
        captureStatus: CaptureViewStatus.idle,
        lastCapturedPhoto: null,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
