import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/mock_location_detector.dart';
import '../../../../core/security/root_detector.dart';

/// LocationIntegrityStatus
/// ----------------------------------------------------------------------
/// Status yang ditampilkan ke UI (indikator GPS di top bar kamera).
/// Selaras dengan wording produk di Bagian 8 & 25 spesifikasi:
/// "Lokasi Valid" / "Memeriksa Lokasi" / "Lokasi Tidak Valid".
/// ----------------------------------------------------------------------
enum LocationIntegrityStatus { checking, valid, invalid }

class LocationIntegrityCheckResult {
  final LocationIntegrityStatus status;
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  const LocationIntegrityCheckResult({
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}

/// ValidateLocationIntegrity (UseCase)
/// ----------------------------------------------------------------------
/// Satu usecase = satu aksi bisnis: memvalidasi apakah lokasi & device
/// saat ini layak dipakai untuk mengambil bukti resmi. Dipanggil secara
/// kontinu (mis. tiap beberapa detik) selagi layar kamera terbuka, agar
/// indikator GPS di top bar selalu real-time - BUKAN dipanggil sekali
/// saat tombol capture ditekan, supaya user sudah tahu status lokasi
/// SEBELUM mereka mencoba mengambil foto.
/// ----------------------------------------------------------------------
class ValidateLocationIntegrity {
  final MockLocationDetector _mockLocationDetector;
  final RootDetector _rootDetector;

  ValidateLocationIntegrity({
    required MockLocationDetector mockLocationDetector,
    required RootDetector rootDetector,
  })  : _mockLocationDetector = mockLocationDetector,
        _rootDetector = rootDetector;

  Future<Either<Failure, LocationIntegrityCheckResult>> call() async {
    try {
      final locationResult =
          await _mockLocationDetector.getValidatedPosition();
      final isDeviceCompromised =
          await _rootDetector.isDeviceCompromised();

      final isFullyValid = locationResult.isValid && !isDeviceCompromised;

      if (isDeviceCompromised) {
        return const Left(DeviceIntegrityFailure());
      }

      return Right(
        LocationIntegrityCheckResult(
          status: isFullyValid
              ? LocationIntegrityStatus.valid
              : LocationIntegrityStatus.invalid,
          latitude: locationResult.position.latitude,
          longitude: locationResult.position.longitude,
          accuracyMeters: locationResult.accuracyInMeters,
        ),
      );
    } catch (e) {
      // Pertahankan pesan asli dari MockLocationDetector (mis. "Layanan
      // lokasi (GPS) perangkat tidak aktif.", "Izin lokasi ditolak.")
      // alih-alih menimpa dengan pesan generik - pesan ini SUDAH ditulis
      // dalam Bahasa Indonesia yang jelas & actionable (Bagian 17), jadi
      // aman ditampilkan langsung ke user tanpa membocorkan detail teknis.
      final message = e.toString().replaceFirst('Exception: ', '');
      return Left(LocationInvalidFailure(message));
    }
  }
}
