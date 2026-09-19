import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'live_location_repository.dart';

/// LiveLocationTrackingService
/// ----------------------------------------------------------------------
/// Menjembatani stream GPS (`package:geolocator`, sudah dipakai di
/// `core/geo/fast_location_service.dart` untuk kamera geotag) ke
/// `LiveLocationRepository` (Firestore). MODUL TERPISAH - sengaja TIDAK
/// memakai instance `FastLocationService` yang ada karena tujuannya
/// berbeda: `FastLocationService` dioptimalkan untuk capture atomik
/// sekali-jepret dengan anti-mock ketat & escalation agresif, sedangkan
/// kelas ini untuk streaming posisi KONTINU selama sesi lapangan
/// berlangsung ke database real-time.
///
/// `distanceFilter: 10` meter (bukan 0 seperti kamera) sengaja dipakai
/// agar tidak menulis ke Firestore pada setiap sentimeter pergerakan -
/// hemat baterai & kuota tanpa mengorbankan kegunaan "posisi live di
/// peta".
/// ----------------------------------------------------------------------
class LiveLocationTrackingService {
  LiveLocationTrackingService({LiveLocationRepository? repository})
    : _repository = repository ?? LiveLocationRepository();

  /// Instance app-wide dipakai oleh integrasi login produksi (lihat
  /// LoginController.submitWithGoogle & AuthRepositoryImpl.logout) -
  /// WAJIB singleton, bukan instance lokal, karena `StreamSubscription`
  /// GPS-nya harus tetap hidup melewati batas hidup LoginController
  /// (yang di-dispose begitu navigasi berpindah dari LoginPage). Modul
  /// demo/beta (`presentation/live_tracking_page.dart`) sengaja tetap
  /// memakai instance-nya sendiri (page-scoped, konstruktor publik di
  /// atas) - keduanya tetap didukung berdampingan.
  static final LiveLocationTrackingService instance =
      LiveLocationTrackingService();

  final LiveLocationRepository _repository;
  StreamSubscription<Position>? _subscription;
  String? _activeUserId;

  bool get isTracking => _subscription != null;

  /// Meminta izin lokasi (jika belum) lalu mulai memancarkan posisi
  /// [userId] ke Firestore setiap kali bergeser >= 10 meter. Melempar
  /// `LocationServiceDisabledException`/`PermissionDeniedException`
  /// (dari package geolocator) apa adanya jika izin/GPS belum siap -
  /// pemanggil yang menampilkan pesan ke user.
  Future<void> startTracking(String userId) async {
    if (_activeUserId == userId && _subscription != null) return;
    await stopTracking();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Izin lokasi diperlukan untuk pelacakan lapangan real-time.',
      );
    }

    _activeUserId = userId;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: _buildLocationSettings(),
        ).listen((position) {
          // Konsisten dengan kebijakan anti-mock Tulap.id di FastLocationService.
          if (position.isMocked) return;
          _repository.updateLocation(
            userId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            speed: position.speed,
            heading: position.heading,
          );
        });
  }

  /// Menghentikan stream GPS. Set [clearRemote] true untuk juga menghapus
  /// dokumen posisi terakhir user dari Firestore (mis. saat logout/akhir
  /// sesi lapangan) - defaultnya false karena "posisi terakhir yang
  /// diketahui" biasanya masih berguna untuk ditampilkan sesaat setelah
  /// tracking berhenti.
  Future<void> stopTracking({bool clearRemote = false}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (clearRemote && _activeUserId != null) {
      await _repository.clearLocation(_activeUserId!);
    }
    _activeUserId = null;
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.other,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }
}
