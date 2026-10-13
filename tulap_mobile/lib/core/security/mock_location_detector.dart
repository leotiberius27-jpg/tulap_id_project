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
/// dipercaya, dengan menggabungkan beberapa sinyal praktis untuk
/// kebutuhan bukti lapangan:
///   1. Flag `isMocked` dari sistem Android/iOS (via package geolocator).
///   2. Akurasi GPS - threshold lebih ketat (30m) untuk meningkatkan
///      kepercayaan bukti.
///   3. Waktu tunggu (timeout) sedang diperpanjang agar device punya
///      kesempatan memperoleh fix yang lebih baik (6s).
///
/// Implementasi ini dirancang mudah disesuaikan: ubah konstanta di atas
/// tanpa mengubah logika utama.
/// ----------------------------------------------------------------------
class MockLocationDetector {
  static const double _maxAcceptableAccuracyMeters = 30.0;
  static const Duration _locationTimeout = Duration(seconds: 6);

  /// Mengevaluasi objek [Position] yang sudah didapat secara instan
  /// tanpa memicu I/O GPS baru (dipakai untuk Fast Pipeline & atomic capture).
  LocationIntegrityResult evaluatePosition(Position position) {
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

  /// Mengambil posisi terkini device dan mengevaluasi integritasnya.
  /// Melempar exception jika GPS tidak aktif / izin belum diberikan.
  Future<LocationIntegrityResult> getValidatedPosition({
    Position? fallbackPosition,
  }) async {
    if (fallbackPosition != null) {
      return evaluatePosition(fallbackPosition);
    }

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

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp!).inMinutes <= 15 &&
          lastKnown.accuracy <= _maxAcceptableAccuracyMeters) {
        return evaluatePosition(lastKnown);
      }
    } catch (_) {}

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _locationTimeout,
    );

    return evaluatePosition(position);
  }
}
