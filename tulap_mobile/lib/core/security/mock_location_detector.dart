import 'package:geolocator/geolocator.dart';

/// LocationIntegrityResult
/// ----------------------------------------------------------------------
/// Hasil pemeriksaan integritas lokasi. `isValid` menentukan apakah
/// capture bukti resmi boleh dilanjutkan.
/// ----------------------------------------------------------------------
class LocationIntegrityResult {
  final bool isValid;
  final bool isMockLocationDetected;
  final double accuracyInMeters;
  final Position position;

  const LocationIntegrityResult({
    required this.isValid,
    required this.isMockLocationDetected,
    required this.accuracyInMeters,
    required this.position,
  });
}

/// MockLocationDetector
/// ----------------------------------------------------------------------
/// Bertugas memeriksa apakah lokasi yang dilaporkan device dapat
/// dipercaya, dengan menggabungkan tiga sinyal:
///   1. Flag `isMocked` dari sistem Android/iOS (via package geolocator,
///      yang di Android memanfaatkan Location.isFromMockProvider()).
///   2. Akurasi GPS - akurasi yang sangat buruk (>50m) dianggap
///      mencurigakan untuk keperluan bukti resmi.
///   3. (Opsional, disiapkan untuk pengembangan lanjutan) Validasi
///      root/jailbreak dari RootDetector, dikombinasikan di usecase.
///
/// Threshold akurasi & timeout SENGAJA dikonfigurasi sebagai konstanta
/// agar mudah disesuaikan tanpa mengubah logic inti.
/// ----------------------------------------------------------------------
class MockLocationDetector {
  static const double _maxAcceptableAccuracyMeters = 50.0;
  static const Duration _locationTimeout = Duration(seconds: 15);

  /// Mengambil posisi terkini device dan mengevaluasi integritasnya.
  /// Melempar [LocationServiceDisabledException] atau
  /// [PermissionDeniedException] bawaan package geolocator jika GPS
  /// tidak aktif / izin belum diberikan - ditangani di layer data.
  Future<LocationIntegrityResult> getValidatedPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi (GPS) perangkat tidak aktif.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Aktifkan lewat pengaturan.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: _locationTimeout,
    );

    // `isMocked` tersedia di Android via geolocator; di iOS package ini
    // akan selalu mengembalikan false karena keterbatasan platform -
    // untuk iOS, sinyal integritas tambahan diambil dari RootDetector
    // (jailbreak check) di usecase ValidateLocationIntegrity.
    final isMocked = position.isMocked;
    final accuracyOk = position.accuracy <= _maxAcceptableAccuracyMeters;

    final isValid = !isMocked && accuracyOk;

    return LocationIntegrityResult(
      isValid: isValid,
      isMockLocationDetected: isMocked,
      accuracyInMeters: position.accuracy,
      position: position,
    );
  }
}
