import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'location_exceptions.dart';
import 'location_fusion_engine.dart';
import 'reverse_geocoder.dart';

/// LocationTier
/// ----------------------------------------------------------------------
/// Klasifikasi 3-level kesiapan lokasi pada Geotag Camera Tulap.id:
/// 1. fastInitial  : Data last-known / fused cache (muncul <1 dtk, status "Lokasi sementara")
/// 2. freshRefining: Stream GPS aktif, akurasi sedang dipersempit (>15m, status "GPS Cukup / Mengunci")
/// 3. verified     : Stream GPS fresh + akurasi <= 15m + lolos anti-mock (status "GPS Akurat")
/// 4. poor         : Akurasi buruk (>50m)
/// 5. disabled     : GPS perangkat dimatikan oleh user
/// 6. denied       : Izin lokasi belum diberikan / ditolak
/// 7. mocked       : Fake GPS / Mock Location terdeteksi (diblokir)
/// ----------------------------------------------------------------------
enum LocationTier {
  none,
  fastInitial,
  freshRefining,
  verified,
  poor,
  disabled,
  denied,
  mocked,
}

/// LocationCachePolicy
/// ----------------------------------------------------------------------
/// Kebijakan masa berlaku cache koordinat LBS:
/// - HOT CACHE  : <= 5 detik (Sangat segar, dapat digunakan instan)
/// - WARM CACHE : <= 30 detik (Cukup segar, memerlukan pembaruan paralel)
/// - STALE      : > 30 detik (Kedaluwarsa, tidak boleh menggantikan fix baru)
/// ----------------------------------------------------------------------
class LocationCachePolicy {
  static const Duration hotCacheMaxAge = Duration(seconds: 5);
  static const Duration warmCacheMaxAge = Duration(seconds: 30);

  static bool isHot(DateTime timestamp) =>
      DateTime.now().difference(timestamp) <= hotCacheMaxAge;

  static bool isWarm(DateTime timestamp) =>
      DateTime.now().difference(timestamp) <= warmCacheMaxAge;

  static bool isStale(DateTime timestamp) =>
      DateTime.now().difference(timestamp) > warmCacheMaxAge;
}

/// LocationQuality
/// ----------------------------------------------------------------------
/// Klasifikasi kualitas akurasi lokasi menurut standar forensik Tulap.id:
/// - excellent : 0 - 10 meter (Sangat Akurat)
/// - good      : >10 - 25 meter (Akurat)
/// - acceptable: >25 - 50 meter (Tersedia)
/// - poor      : >50 meter (Akurasi Rendah)
/// ----------------------------------------------------------------------
enum LocationQuality {
  excellent,
  good,
  acceptable,
  poor;

  static LocationQuality fromAccuracy(double? accuracy) {
    if (accuracy == null) return LocationQuality.poor;
    if (accuracy <= 10.0) return LocationQuality.excellent;
    if (accuracy <= 25.0) return LocationQuality.good;
    if (accuracy <= 50.0) return LocationQuality.acceptable;
    return LocationQuality.poor;
  }

  String labelIndonesian(double? accuracy) {
    final accStr = accuracy != null ? '±${accuracy.round()} m' : '±-- m';
    switch (this) {
      case LocationQuality.excellent:
        return '✓ Lokasi sangat akurat · $accStr';
      case LocationQuality.good:
        return '✓ Lokasi akurat · $accStr';
      case LocationQuality.acceptable:
        return '● Lokasi tersedia · $accStr';
      case LocationQuality.poor:
        return '⚠ Akurasi rendah · $accStr';
    }
  }
}

/// LocationSnapshot
/// ----------------------------------------------------------------------
/// Snapshot atomik lokasi pada detik media diambil (shutter foto / start video).
/// ----------------------------------------------------------------------
class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final DateTime recordedAt;
  final String source;
  final bool isMock;
  final String? address;

  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.recordedAt,
    this.source = 'GPS_FUSED',
    this.isMock = false,
    this.address,
  });

  LocationQuality get quality => LocationQuality.fromAccuracy(accuracy);
}

/// FastLocationData
/// ----------------------------------------------------------------------
/// Representasi terpadu state lokasi real-time.
/// ----------------------------------------------------------------------
class FastLocationData {
  final LocationTier tier;
  final Position? position;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? heading;
  final String? address;
  final DateTime timestamp;
  final bool isMocked;
  final bool isStale;
  final String? errorMessage;

  const FastLocationData({
    required this.tier,
    this.position,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.address,
    required this.timestamp,
    this.isMocked = false,
    this.isStale = false,
    this.errorMessage,
  });

  bool get isGpsLocked => accuracy != null && accuracy! <= 15.0;
  bool get isAcceptable => accuracy != null && accuracy! <= 30.0;
  bool get isUsableForCapture =>
      (tier == LocationTier.verified || isGpsLocked) && !isMocked;

  LocationQuality get quality => LocationQuality.fromAccuracy(accuracy);
  String get qualityBadgeText => quality.labelIndonesian(accuracy);

  LocationSnapshot? toSnapshot({String source = 'GPS_FUSED'}) {
    if (latitude == null || longitude == null) return null;
    return LocationSnapshot(
      latitude: latitude!,
      longitude: longitude!,
      accuracy: accuracy ?? 100.0,
      altitude: altitude ?? position?.altitude,
      heading: heading ?? position?.heading,
      speed: position?.speed,
      recordedAt: timestamp,
      source: source,
      isMock: isMocked,
      address: address,
    );
  }

  FastLocationData copyWith({
    LocationTier? tier,
    Position? position,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    String? address,
    DateTime? timestamp,
    bool? isMocked,
    bool? isStale,
    String? errorMessage,
  }) {
    return FastLocationData(
      tier: tier ?? this.tier,
      position: position ?? this.position,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      isMocked: isMocked ?? this.isMocked,
      isStale: isStale ?? this.isStale,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'FastLocationData(tier: $tier, lat: $latitude, lng: $longitude, acc: ${accuracy?.toStringAsFixed(1)}m, isMock: $isMocked, stale: $isStale)';
}

/// FastLocationService
/// ----------------------------------------------------------------------
/// Engine pusat percepatan deteksi lokasi Tulap.id:
/// - Prefetch / Warm-up singkat (5–10 dtk) saat Activity Workspace dibuka
/// - Mengembalikan lastKnownPosition dalam hitungan milidetik saat kamera dibuka
/// - Membuka stream posisi GPS berkecepatan tinggi dengan setting native Android & iOS
/// - Throttled reverse geocoding paralel (tidak memblokir koordinat & shutter)
/// - Menangkap posisi verified secara atomik saat shutter ditekan (0ms overhead GPS)
/// - Menegakkan anti-mock & root check secara ketat
/// - Manajemen lifecycle baterai: stop stream agresif saat kamera ditutup/background
/// ----------------------------------------------------------------------
class FastLocationService {
  static final FastLocationService _instance = FastLocationService._internal();
  static FastLocationService get instance => _instance;

  FastLocationService._internal();

  /// Ambang akurasi "GPS Akurat" (badge hijau, tier verified).
  static const double verifiedAccuracyMeters = 15.0;

  /// Estimasi yang lebih tua dari ini tidak dipakai mentah-mentah saat
  /// shutter - wajib fix baru (lihat getAtomicCaptureLocation).
  static const Duration captureMaxAge = Duration(seconds: 30);

  /// Lama GPS tetap "panas" setelah panggilan startWarmUp() terakhir.
  /// Setiap layar yang memanggil startWarmUp() memperpanjang jendela ini.
  static const Duration defaultWarmWindow = Duration(minutes: 3);

  /// Mesin fusi Kalman - SATU sumber kebenaran posisi untuk warm-up,
  /// stream kamera, dan shutter.
  final LocationFusionEngine _engine = LocationFusionEngine();

  Position? _warmCandidatePosition;
  Position? _latestVerifiedPosition;
  Position? _lastMockedPosition;
  String? _cachedAddress;
  double? _cachedAddressLat;
  double? _cachedAddressLng;
  bool _isGeocodeInFlight = false;

  StreamSubscription<Position>? _warmSub;
  StreamSubscription<Position>? _activePositionStream;
  Timer? _warmUpTimer;
  bool _isWarmUpStarting = false;
  bool _isCameraStreamRunning = false;
  AppLifecycleListener? _lifecycleListener;

  ReverseGeocoder? _reverseGeocoder;

  /// isSecurityCompromised
  /// ----------------------------------------------------------------------
  /// true SEJAK sesi stream kamera aktif ini mendeteksi mock location -
  /// dipertahankan true sampai stream benar-benar dihentikan & dimulai
  /// ulang dari nol (mis. user menutup lalu membuka lagi layar kamera).
  /// Sengaja TIDAK auto-reset saat sinyal mock hilang begitu saja (mis.
  /// user mematikan app fake-GPS di tengah sesi) - sekali sesi terbukti
  /// terkompromi, sesi itu harus dimulai ulang bersih, bukan diam-diam
  /// pulih sendiri.
  bool _isSecurityCompromised = false;
  bool get isSecurityCompromised => _isSecurityCompromised;

  /// onMockLocationDetected
  /// ----------------------------------------------------------------------
  /// Dipanggil TEPAT SEKALI per sesi stream, pada saat mock location
  /// pertama kali terdeteksi di dalam `startActiveCameraStream()` -
  /// "secure error callback" agar pemanggil (mis. GeotagCameraController)
  /// bisa memicu efek sampingnya sendiri (haptic, log, dsb) di luar
  /// mekanisme `onLocationUpdate` yang sudah ada. Laporan resmi ke
  /// admin/database sendiri sudah ditangani terpisah lewat
  /// `ReportSecurityEvent` (core/security) yang dipanggil dari
  /// GeotagCameraRepositoryImpl tepat saat capture diblokir - callback
  /// ini murni hook tambahan di level deteksi, bukan pengganti jalur itu.
  void Function()? onMockLocationDetected;

  void setReverseGeocoder(ReverseGeocoder geocoder) {
    _reverseGeocoder = geocoder;
  }

  /// checkAndRequestPermissions
  /// ----------------------------------------------------------------------
  /// Pemeriksaan izin & status layanan lokasi yang bisa dipakai ulang di
  /// luar `startActiveCameraStream()` (mis. sebuah layar Pengaturan yang
  /// ingin menyapa user dengan pesan error yang jelas SEBELUM mereka
  /// masuk ke kamera). Melempar exception bertipe dari
  /// `location_exceptions.dart` alih-alih mengembalikan status via
  /// callback, agar pemanggil bisa memakai try-catch biasa.
  Future<void> checkAndRequestPermissions() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException(
          'Izin lokasi ditolak oleh pengguna.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }
  }

  /// Sampel mentah terakhir dari stream warm-up.
  Position? get warmCandidatePosition => _warmCandidatePosition;

  /// Estimasi terfusi terakhir yang akurasinya <= 15 m saat diterima.
  /// Cek umurnya (timestamp) sebelum dipakai - bisa saja sudah lama.
  Position? get latestVerifiedPosition => _latestVerifiedPosition;

  /// Alias nama sesuai spesifikasi ("lastKnownValidLocation").
  Position? get lastKnownValidLocation => _latestVerifiedPosition;

  /// Ketidakpastian (meter) estimasi saat ini, sudah termasuk umur.
  double? get currentAccuracy => _engine.accuracyAt(DateTime.now());

  /// Estimasi posisi terbaik (hasil fusi Kalman semua fix yang diterima).
  Position? get latestCandidatePosition =>
      _engine.estimate ?? _warmCandidatePosition;

  // ====================================================================
  // 0. FUSION HELPERS
  // ====================================================================
  /// Memasukkan satu fix (non-mock) ke mesin fusi. `observedAt` default
  /// = sekarang (fix live dari stream). Untuk last-known position oper
  /// timestamp aslinya agar umurnya dihitung jujur.
  bool _ingest(Position pos, {DateTime? observedAt}) {
    if (pos.isMocked) return false;
    final now = DateTime.now();
    var at = observedAt ?? now;
    if (at.isAfter(now)) at = now;
    final accepted = _engine.addSample(pos, observedAt: at);
    if (accepted) {
      final acc = _engine.accuracyAt(now);
      if (acc != null && acc <= verifiedAccuracyMeters) {
        _latestVerifiedPosition = _engine.estimate;
      }
    }
    return accepted;
  }

  LocationTier _tierAt(DateTime now) {
    final acc = _engine.accuracyAt(now);
    final age = _engine.ageAt(now);
    if (acc == null || age == null) return LocationTier.none;
    if (age > captureMaxAge) return LocationTier.fastInitial;
    if (acc <= verifiedAccuracyMeters) return LocationTier.verified;
    if (acc <= 50.0) return LocationTier.freshRefining;
    return LocationTier.poor;
  }

  /// Snapshot estimasi terfusi untuk UI / shutter. `accuracy` sudah
  /// termasuk pertumbuhan ketidakpastian karena umur.
  FastLocationData _snapshot({DateTime? timestamp, String? address}) {
    final now = DateTime.now();
    final est = _engine.estimate;
    if (est == null) {
      return FastLocationData(tier: LocationTier.none, timestamp: now);
    }
    final age = _engine.ageAt(now) ?? Duration.zero;
    return FastLocationData(
      tier: _tierAt(now),
      position: est,
      latitude: est.latitude,
      longitude: est.longitude,
      accuracy: _engine.accuracyAt(now),
      altitude: est.altitude,
      heading: est.heading,
      address: address ?? _cachedAddress,
      timestamp: timestamp ?? now,
      isMocked: false,
      isStale: age > captureMaxAge,
    );
  }

  FastLocationData _mockedData(Position pos) => FastLocationData(
    tier: LocationTier.mocked,
    position: pos,
    latitude: pos.latitude,
    longitude: pos.longitude,
    accuracy: pos.accuracy,
    timestamp: DateTime.now(),
    isMocked: true,
  );

  void _flagMocked(Position pos) {
    _lastMockedPosition = pos;
    if (!_isSecurityCompromised) {
      _isSecurityCompromised = true;
      onMockLocationDetected?.call();
    }
  }

  // ====================================================================
  // 1. WARM-UP: GPS TETAP PANAS SELAMA APLIKASI DIBUKA
  // ====================================================================
  /// Dipanggil saat aplikasi dibuka & di layar-layar kerja (Beranda,
  /// daftar/detail tugas). Berbeda dari versi lama yang mematikan GPS
  /// begitu dapat satu fix ±15 m (sehingga fix itu sudah basi saat
  /// kamera dibuka beberapa menit kemudian), stream warm-up sekarang
  /// tetap berjalan selama [timeout] sejak panggilan TERAKHIR - mirip
  /// aplikasi GPS kamera profesional yang menjaga GPS panas selama
  /// aplikasi di layar. Otomatis berhenti saat aplikasi ke background
  /// dan hidup lagi saat kembali ke depan.
  Future<void> startWarmUp({Duration timeout = defaultWarmWindow}) async {
    if (_isCameraStreamRunning) return;
    _ensureLifecycleListener();

    // Stream sudah jalan -> cukup perpanjang jendelanya (rolling).
    if (_warmSub != null) {
      _armWarmWindow(timeout);
      return;
    }
    if (_isWarmUpStarting) return;
    _isWarmUpStarting = true;

    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      if (_isCameraStreamRunning) return;

      debugPrint('[FAST_LOCATION] 🚀 Warm-up GPS stream started.');

      // 1. Last known = jangkar instan (umur dihitung jujur oleh fusi).
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && !lastKnown.isMocked) {
        _warmCandidatePosition ??= lastKnown;
        _ingest(lastKnown, observedAt: lastKnown.timestamp);
      }
      if (_isCameraStreamRunning) return;

      // 2. Stream 1 Hz (laju native chip GNSS) - hemat baterai namun
      // estimasi selalu < 1-2 detik umurnya saat kamera dibuka.
      _warmSub =
          Geolocator.getPositionStream(
            locationSettings: _buildPlatformLocationSettings(
              LocationAccuracy.high,
              interval: const Duration(seconds: 1),
            ),
          ).listen(
            (pos) {
              if (pos.isMocked) return;
              _warmCandidatePosition = pos;
              _ingest(pos);
            },
            onError: (Object e) {
              debugPrint('[FAST_LOCATION] ⚠️ Warm stream error: $e');
              _cancelWarmStream();
            },
            cancelOnError: true,
          );
      _armWarmWindow(timeout);
    } catch (e) {
      debugPrint('[FAST_LOCATION] ⚠️ Warm-up error: $e');
    } finally {
      _isWarmUpStarting = false;
    }
  }

  void _armWarmWindow(Duration timeout) {
    _warmUpTimer?.cancel();
    _warmUpTimer = Timer(timeout, () {
      debugPrint('[FAST_LOCATION] ⏱️ Warm window ended, GPS released.');
      _cancelWarmStream();
    });
  }

  void stopWarmUp() {
    _warmUpTimer?.cancel();
    _warmUpTimer = null;
    _cancelWarmStream();
  }

  void _cancelWarmStream() {
    _warmSub?.cancel();
    _warmSub = null;
  }

  void _ensureLifecycleListener() {
    if (_lifecycleListener != null) return;
    try {
      _lifecycleListener = AppLifecycleListener(
        onHide: () {
          if (_warmSub != null) {
            debugPrint('[FAST_LOCATION] 💤 App hidden, warm GPS paused.');
          }
          stopWarmUp();
        },
        onShow: () {
          if (!_isCameraStreamRunning) startWarmUp();
        },
      );
    } catch (_) {
      // Tanpa WidgetsBinding (mis. unit test) - warm-up tetap jalan,
      // hanya tanpa jeda otomatis saat background.
    }
  }

  // ====================================================================
  // 2. ACTIVE GEOTAG CAMERA STREAM PIPELINE
  // ====================================================================
  /// Membuka stream posisi GPS berkecepatan tinggi saat layar kamera aktif.
  Future<StreamSubscription<Position>?> startActiveCameraStream({
    required void Function(FastLocationData data) onLocationUpdate,
    Position? initialCandidate,
  }) async {
    // Stream kamera menggantikan stream warm-up; estimasi fusi DIBAWA.
    stopWarmUp();

    await stopActiveCameraStream();
    _isCameraStreamRunning = true;
    // Sesi baru = clean slate keamanan.
    _isSecurityCompromised = false;
    _lastMockedPosition = null;

    final startTime = DateTime.now();
    debugPrint('[FAST_LOCATION_PERF] 📷 camera_open = 0ms');

    // 1. Periksa Service & Izin
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        onLocationUpdate(
          FastLocationData(
            tier: LocationTier.disabled,
            timestamp: DateTime.now(),
            errorMessage: 'Layanan lokasi (GPS) perangkat tidak aktif.',
          ),
        );
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onLocationUpdate(
            FastLocationData(
              tier: LocationTier.denied,
              timestamp: DateTime.now(),
              errorMessage: 'Izin lokasi ditolak oleh pengguna.',
            ),
          );
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        onLocationUpdate(
          FastLocationData(
            tier: LocationTier.denied,
            timestamp: DateTime.now(),
            errorMessage:
                'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan.',
          ),
        );
        return null;
      }
    } catch (e) {
      debugPrint('[FAST_LOCATION] ℹ️ Location service check fallback: $e');
    }
    if (!_isCameraStreamRunning) return null;

    // 2. TAMPILKAN ESTIMASI YANG ADA SEGERA (<100 ms)
    if (initialCandidate != null && initialCandidate.isMocked) {
      _flagMocked(initialCandidate);
      onLocationUpdate(_mockedData(initialCandidate));
    } else if (initialCandidate != null && !_engine.hasEstimate) {
      _ingest(initialCandidate, observedAt: initialCandidate.timestamp);
    }

    if (!_engine.hasEstimate) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && !lastKnown.isMocked) {
          _ingest(lastKnown, observedAt: lastKnown.timestamp);
        }
      } catch (_) {}
    }
    if (!_isCameraStreamRunning) return null;

    if (_engine.hasEstimate) {
      final initial = _snapshot();
      debugPrint(
        '[FAST_LOCATION_PERF] ⚡ initial_estimate = ${DateTime.now().difference(startTime).inMilliseconds}ms (tier: ${initial.tier}, ±${initial.accuracy?.round()}m)',
      );
      onLocationUpdate(initial);
      _triggerAsyncReverseGeocode(
        initial.latitude!,
        initial.longitude!,
        onLocationUpdate,
      );
    }
    // Tanpa estimasi: sengaja tidak mengirim tier `none` - itu akan
    // menimpa hasil validasi lokasi awal milik pemanggil.

    // 3. FIX CEPAT PARALEL: getCurrentLocation fused (Wi-Fi/sel/GNSS)
    // sering memberi fix segar < 1 detik saat GNSS masih cold-start;
    // stream di bawah lalu terus mempersempitnya lewat fusi.
    unawaited(_parallelQuickFix(onLocationUpdate, startTime));

    // 4. STREAM GNSS AKURASI TERTINGGI selama kamera terbuka. Sengaja
    // TANPA "eskalasi" yang memutus & membuka ulang stream: di Android
    // best/bestForNavigation sama-sama PRIORITY_HIGH_ACCURACY sehingga
    // eskalasi hanya menciptakan jeda tanpa data.
    try {
      bool firstFreshLogged = false;
      _activePositionStream =
          Geolocator.getPositionStream(
            locationSettings: _buildPlatformLocationSettings(
              LocationAccuracy.bestForNavigation,
              interval: const Duration(milliseconds: 100),
            ),
          ).listen(
            (pos) {
              if (!_isCameraStreamRunning) return;

              if (!firstFreshLogged) {
                firstFreshLogged = true;
                debugPrint(
                  '[FAST_LOCATION_PERF] 🟢 first_fresh_gps = ${DateTime.now().difference(startTime).inMilliseconds}ms (raw ±${pos.accuracy.round()}m)',
                );
              }

              if (pos.isMocked) {
                // Kirim SATU update bertier `mocked` (agar UI menampilkan
                // modal blokir), lalu hentikan stream sepenuhnya - sesi yang
                // terbukti terkompromi tidak boleh pulih diam-diam.
                onLocationUpdate(_mockedData(pos));
                _flagMocked(pos);
                stopActiveCameraStream();
                return;
              }

              _ingest(pos);
              final data = _snapshot();
              onLocationUpdate(data);
              _triggerAsyncReverseGeocode(
                data.latitude!,
                data.longitude!,
                onLocationUpdate,
              );
            },
            onError: (Object err) {
              debugPrint('[FAST_LOCATION] ⚠️ Stream error: $err');
            },
          );
    } catch (e) {
      debugPrint(
        '[FAST_LOCATION] ℹ️ Position stream initialization fallback: $e',
      );
    }

    return _activePositionStream;
  }

  Future<void> _parallelQuickFix(
    void Function(FastLocationData data) onLocationUpdate,
    DateTime startTime,
  ) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _buildPlatformLocationSettings(
          LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
        ),
      );
      if (!_isCameraStreamRunning) return;
      if (pos.isMocked) {
        onLocationUpdate(_mockedData(pos));
        _flagMocked(pos);
        stopActiveCameraStream();
        return;
      }
      if (_ingest(pos)) {
        final data = _snapshot();
        debugPrint(
          '[FAST_LOCATION_PERF] ⚡ parallel_quick_fix = ${DateTime.now().difference(startTime).inMilliseconds}ms (raw ±${pos.accuracy.round()}m, fused ±${data.accuracy?.round()}m)',
        );
        onLocationUpdate(data);
      }
    } catch (_) {
      // Timeout / tidak ada fix cepat - stream utama tetap berjalan.
    }
  }

  Future<void> stopActiveCameraStream() async {
    _isCameraStreamRunning = false;
    await _activePositionStream?.cancel();
    _activePositionStream = null;
    debugPrint('[FAST_LOCATION] 🛑 Camera stream stopped and released.');
  }

  // ====================================================================
  // 3. ATOMIC CAPTURE LOCATION (0 ms SHUTTER LATENCY)
  // ====================================================================
  /// Mengambil lokasi saat tombol jepret ditekan. Bila estimasi fusi
  /// berumur <= [captureMaxAge] dipakai instan (0 ms). Bila tidak, minta
  /// fix baru maks 2.5 detik - TIDAK PERNAH diam-diam mencap koordinat
  /// basi sebagai lokasi foto.
  Future<FastLocationData> getAtomicCaptureLocation() async {
    final now = DateTime.now();

    // 0. Sesi terbukti mock -> tetap laporkan mock (diblokir pemanggil).
    final mocked = _lastMockedPosition;
    if (_isSecurityCompromised && mocked != null) {
      return _mockedData(mocked);
    }

    // 1. Estimasi fusi yang masih segar.
    final age = _engine.ageAt(now);
    if (age != null && age <= captureMaxAge) {
      final data = _snapshot(timestamp: now);
      debugPrint(
        '[FAST_LOCATION_PERF] 📸 shutter_atomic = 0ms delay (±${data.accuracy?.round()}m, age ${age.inMilliseconds}ms, ${_engine.sampleCount} fixes fused)',
      );
      return data;
    }

    // 2. Estimasi basi / kosong -> fix baru singkat.
    try {
      debugPrint('[FAST_LOCATION] ⚠️ Estimate stale, requesting 2.5s fix...');
      final quickPos = await Geolocator.getCurrentPosition(
        locationSettings: _buildPlatformLocationSettings(
          LocationAccuracy.high,
          timeLimit: const Duration(milliseconds: 2500),
        ),
      );
      if (quickPos.isMocked) {
        _flagMocked(quickPos);
        return _mockedData(quickPos);
      }
      _ingest(quickPos);
      return _snapshot(timestamp: now);
    } catch (_) {}

    // 3. Fallback: estimasi lama dengan ketidakpastian jujur, ditandai
    // stale & poor agar UI/validasi bisa menolaknya.
    if (!_engine.hasEstimate) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          if (lastKnown.isMocked) return _mockedData(lastKnown);
          _ingest(lastKnown, observedAt: lastKnown.timestamp);
        }
      } catch (_) {}
    }
    final fallback = _snapshot(timestamp: now);
    return fallback.copyWith(tier: LocationTier.poor, isStale: true);
  }

  // ====================================================================
  // 4. ASYNCHRONOUS THROTTLED REVERSE GEOCODING
  // ====================================================================
  Future<void> _triggerAsyncReverseGeocode(
    double lat,
    double lng,
    void Function(FastLocationData data) onLocationUpdate,
  ) async {
    if (_reverseGeocoder == null) return;

    // Cek cache jarak (< 40 meter tidak perlu request ulang)
    if (_cachedAddressLat != null &&
        _cachedAddressLng != null &&
        _cachedAddress != null) {
      final dLat = (lat - _cachedAddressLat!).abs();
      final dLng = (lng - _cachedAddressLng!).abs();
      if (dLat < 0.0004 && dLng < 0.0004) {
        return;
      }
    }
    // Satu request sekaligus - tick stream 100 ms tidak boleh membanjiri
    // geocoder selagi request sebelumnya masih berjalan.
    if (_isGeocodeInFlight) return;
    _isGeocodeInFlight = true;

    try {
      final address = await _reverseGeocoder!.reverseGeocode(
        latitude: lat,
        longitude: lng,
      );

      _cachedAddress = address;
      _cachedAddressLat = lat;
      _cachedAddressLng = lng;
      if (_isCameraStreamRunning && _engine.hasEstimate) {
        onLocationUpdate(_snapshot(address: address));
      }
    } catch (_) {
      // Offline / error: Koordinat tetap valid, alamat di-update nanti.
    } finally {
      _isGeocodeInFlight = false;
    }
  }

  // ====================================================================
  // 5. PLATFORM SETTINGS
  // ====================================================================
  /// Android: geolocator memakai FusedLocationProviderClient (GNSS +
  /// Wi-Fi + sel + sensor); accuracy high/best/bestForNavigation =
  /// PRIORITY_HIGH_ACCURACY. iOS: `pauseLocationUpdatesAutomatically`
  /// WAJIB false - petugas yang berdiri diam memotret justru kondisi
  /// yang membuat iOS menjeda update bila true.
  LocationSettings _buildPlatformLocationSettings(
    LocationAccuracy accuracy, {
    Duration interval = const Duration(seconds: 1),
    Duration? timeLimit,
  }) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        intervalDuration: interval,
        timeLimit: timeLimit,
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: 0,
      timeLimit: timeLimit,
    );
  }
}
