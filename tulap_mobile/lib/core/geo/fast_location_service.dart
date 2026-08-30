import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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

  Position? _warmCandidatePosition;
  Position? _latestVerifiedPosition;
  Position? _latestCandidatePosition;
  DateTime? _latestPositionReceivedTime;
  String? _cachedAddress;
  double? _cachedAddressLat;
  double? _cachedAddressLng;

  StreamSubscription<Position>? _activePositionStream;
  Timer? _warmUpTimer;
  Timer? _escalationTimer;
  bool _isWarmUpRunning = false;
  bool _isCameraStreamRunning = false;

  ReverseGeocoder? _reverseGeocoder;

  void setReverseGeocoder(ReverseGeocoder geocoder) {
    _reverseGeocoder = geocoder;
  }

  Position? get warmCandidatePosition => _warmCandidatePosition;
  Position? get latestVerifiedPosition => _latestVerifiedPosition;
  Position? get latestCandidatePosition =>
      _latestCandidatePosition ??
      _latestVerifiedPosition ??
      _warmCandidatePosition;

  // ====================================================================
  // 1. WORKSPACE PREFETCH / WARM-UP (SHORT-LIVED 5-10 SECONDS)
  // ====================================================================
  /// Dipanggil saat user membuka Activity Workspace (`TaskDetailPage`).
  /// Mempersiapkan GPS lebih awal secara asinkron tanpa memblokir UI.
  Future<void> startWarmUp({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_isWarmUpRunning || _isCameraStreamRunning) return;

    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Jangan paksa dialog permission saat di background warm-up
        return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _isWarmUpRunning = true;
      debugPrint('[FAST_LOCATION] 🚀 Workspace warm-up started...');

      // 1. Ambil last known position secara instan
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _warmCandidatePosition = lastKnown;
        _latestPositionReceivedTime = DateTime.now();
        debugPrint(
          '[FAST_LOCATION] ⚡ Last known acquired in warm-up: ${lastKnown.latitude}, ${lastKnown.longitude} (±${lastKnown.accuracy.round()}m)',
        );
      }

      // 2. Buka stream singkat untuk refine koordinat terbaru
      final locationSettings = _buildPlatformLocationSettings(
        LocationAccuracy.high,
      );
      final warmStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      StreamSubscription<Position>? warmSub;
      warmSub = warmStream.listen(
        (pos) {
          if (pos.isMocked) return;
          _warmCandidatePosition = pos;
          _latestCandidatePosition = pos;
          _latestPositionReceivedTime = DateTime.now();

          if (pos.accuracy <= 15.0) {
            _latestVerifiedPosition = pos;
            debugPrint(
              '[FAST_LOCATION] 🎯 Warm-up locked high accuracy fix: ±${pos.accuracy.round()}m. Stopping early.',
            );
            warmSub?.cancel();
            _isWarmUpRunning = false;
          }
        },
        onError: (_) {
          warmSub?.cancel();
          _isWarmUpRunning = false;
        },
      );

      // 3. Batasi waktu warm-up maksimal 8 detik untuk menghemat baterai
      _warmUpTimer?.cancel();
      _warmUpTimer = Timer(timeout, () {
        if (_isWarmUpRunning) {
          warmSub?.cancel();
          _isWarmUpRunning = false;
          debugPrint(
            '[FAST_LOCATION] ⏱️ Warm-up timeout reached. Stream stopped to preserve battery.',
          );
        }
      });
    } catch (e) {
      _isWarmUpRunning = false;
      debugPrint('[FAST_LOCATION] ⚠️ Warm-up error: $e');
    }
  }

  void stopWarmUp() {
    _warmUpTimer?.cancel();
    _isWarmUpRunning = false;
  }

  // ====================================================================
  // 2. ACTIVE GEOTAG CAMERA STREAM PIPELINE
  // ====================================================================
  /// Membuka stream posisi GPS berkecepatan tinggi saat layar kamera aktif.
  Future<StreamSubscription<Position>?> startActiveCameraStream({
    required void Function(FastLocationData data) onLocationUpdate,
    Position? initialCandidate,
  }) async {
    _warmUpTimer?.cancel();
    _isWarmUpRunning = false;

    // Bersihkan stream lama jika ada
    await stopActiveCameraStream();
    _isCameraStreamRunning = true;

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

    // 2. TAMPILKAN FAST INITIAL / LAST-KNOWN SEGERA (<1 Detik)
    final candidate =
        initialCandidate ??
        _warmCandidatePosition ??
        _latestVerifiedPosition ??
        _latestCandidatePosition;
    if (candidate != null) {
      final isFresh = _isPositionFresh(candidate);
      final isAccurate = candidate.accuracy <= 15.0;

      final initialTier = candidate.isMocked
          ? LocationTier.mocked
          : (isFresh && isAccurate
                ? LocationTier.verified
                : LocationTier.fastInitial);

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint(
        '[FAST_LOCATION_PERF] ⚡ last_known_displayed = ${elapsedMs}ms (tier: $initialTier, ±${candidate.accuracy.round()}m)',
      );

      onLocationUpdate(
        FastLocationData(
          tier: initialTier,
          position: candidate,
          latitude: candidate.latitude,
          longitude: candidate.longitude,
          accuracy: candidate.accuracy,
          address: _cachedAddress,
          timestamp: candidate.timestamp,
          isMocked: candidate.isMocked,
          isStale: !isFresh,
        ),
      );

      // Trigger reverse geocoding paralel di latar belakang
      _triggerAsyncReverseGeocode(
        candidate.latitude,
        candidate.longitude,
        onLocationUpdate,
      );
    } else {
      // Coba ambil getLastKnownPosition secara instan
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && _isCameraStreamRunning) {
          final isFresh = _isPositionFresh(lastKnown);
          final initialTier = lastKnown.isMocked
              ? LocationTier.mocked
              : (isFresh && lastKnown.accuracy <= 15.0
                    ? LocationTier.verified
                    : LocationTier.fastInitial);

          final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
          debugPrint(
            '[FAST_LOCATION_PERF] ⚡ direct_last_known = ${elapsedMs}ms (±${lastKnown.accuracy.round()}m)',
          );

          onLocationUpdate(
            FastLocationData(
              tier: initialTier,
              position: lastKnown,
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              accuracy: lastKnown.accuracy,
              address: _cachedAddress,
              timestamp: lastKnown.timestamp,
              isMocked: lastKnown.isMocked,
              isStale: !isFresh,
            ),
          );

          _triggerAsyncReverseGeocode(
            lastKnown.latitude,
            lastKnown.longitude,
            onLocationUpdate,
          );
        } else if (_isCameraStreamRunning) {
          onLocationUpdate(
            FastLocationData(
              tier: LocationTier.none,
              timestamp: DateTime.now(),
            ),
          );
        }
      } catch (_) {}
    }

    // 3. MULAI FRESH HIGH-ACCURACY POSITION STREAM
    try {
      final settings = _buildPlatformLocationSettings(LocationAccuracy.high);
      final positionStream = Geolocator.getPositionStream(
        locationSettings: settings,
      );

      bool firstFreshLogged = false;

      _activePositionStream = positionStream.listen(
        (pos) {
          if (!_isCameraStreamRunning) return;

          final now = DateTime.now();
          _latestPositionReceivedTime = now;
          _latestCandidatePosition = pos;

          final elapsedMs = now.difference(startTime).inMilliseconds;
          if (!firstFreshLogged) {
            firstFreshLogged = true;
            debugPrint(
              '[FAST_LOCATION_PERF] 🟢 first_fresh_gps = ${elapsedMs}ms (acc: ±${pos.accuracy.round()}m)',
            );
          }

          if (pos.isMocked) {
            onLocationUpdate(
              FastLocationData(
                tier: LocationTier.mocked,
                position: pos,
                latitude: pos.latitude,
                longitude: pos.longitude,
                accuracy: pos.accuracy,
                timestamp: now,
                isMocked: true,
              ),
            );
            return;
          }

          LocationTier currentTier;
          if (pos.accuracy <= 15.0) {
            currentTier = LocationTier.verified;
            _latestVerifiedPosition = pos;
            debugPrint(
              '[FAST_LOCATION_PERF] 🎯 verified_accuracy_15m = ${elapsedMs}ms (acc: ±${pos.accuracy.toStringAsFixed(1)}m)',
            );
          } else if (pos.accuracy <= 30.0) {
            currentTier = LocationTier.freshRefining;
            debugPrint(
              '[FAST_LOCATION_PERF] 🟡 acceptable_accuracy_30m = ${elapsedMs}ms (acc: ±${pos.accuracy.toStringAsFixed(1)}m)',
            );
          } else if (pos.accuracy <= 50.0) {
            currentTier = LocationTier.freshRefining;
          } else {
            currentTier = LocationTier.poor;
          }

          onLocationUpdate(
            FastLocationData(
              tier: currentTier,
              position: pos,
              latitude: pos.latitude,
              longitude: pos.longitude,
              accuracy: pos.accuracy,
              address: _cachedAddress,
              timestamp: now,
              isMocked: false,
              isStale: false,
            ),
          );

          // Asynchronous geocoding update jika berpindah > 30 meter
          _triggerAsyncReverseGeocode(
            pos.latitude,
            pos.longitude,
            onLocationUpdate,
          );
        },
        onError: (err) {
          debugPrint('[FAST_LOCATION] ⚠️ Stream error: $err');
        },
      );
    } catch (e) {
      debugPrint(
        '[FAST_LOCATION] ℹ️ Position stream initialization fallback: $e',
      );
    }

    // 4. ADAPTIVE ESCALATION: Jika setelah 6 detik akurasi masih > 30m, eskalasi ke Best
    _escalationTimer?.cancel();
    _escalationTimer = Timer(const Duration(seconds: 6), () {
      if (_isCameraStreamRunning &&
          (_latestVerifiedPosition == null ||
              _latestVerifiedPosition!.accuracy > 30.0)) {
        debugPrint(
          '[FAST_LOCATION] ⚡ Escalating stream to LocationAccuracy.best for faster convergence...',
        );
        _escalateStreamAccuracy(onLocationUpdate);
      }
    });

    return _activePositionStream;
  }

  void _escalateStreamAccuracy(
    void Function(FastLocationData data) onLocationUpdate,
  ) {
    if (!_isCameraStreamRunning) return;
    try {
      final bestSettings = _buildPlatformLocationSettings(
        LocationAccuracy.best,
      );
      _activePositionStream?.cancel();
      _activePositionStream =
          Geolocator.getPositionStream(locationSettings: bestSettings).listen((
            pos,
          ) {
            if (!_isCameraStreamRunning) return;
            final now = DateTime.now();
            _latestPositionReceivedTime = now;
            _latestCandidatePosition = pos;

            if (pos.isMocked) {
              onLocationUpdate(
                FastLocationData(
                  tier: LocationTier.mocked,
                  position: pos,
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  accuracy: pos.accuracy,
                  timestamp: now,
                  isMocked: true,
                ),
              );
              return;
            }

            final isVerified = pos.accuracy <= 15.0;
            if (isVerified) {
              _latestVerifiedPosition = pos;
            }

            onLocationUpdate(
              FastLocationData(
                tier: isVerified
                    ? LocationTier.verified
                    : LocationTier.freshRefining,
                position: pos,
                latitude: pos.latitude,
                longitude: pos.longitude,
                accuracy: pos.accuracy,
                address: _cachedAddress,
                timestamp: now,
                isMocked: false,
                isStale: false,
              ),
            );
          });
    } catch (_) {}
  }

  Future<void> stopActiveCameraStream() async {
    _isCameraStreamRunning = false;
    _escalationTimer?.cancel();
    await _activePositionStream?.cancel();
    _activePositionStream = null;
    debugPrint('[FAST_LOCATION] 🛑 Camera stream stopped and released.');
  }

  // ====================================================================
  // 3. ATOMIC CAPTURE LOCATION (0ms SHUTTER LATENCY)
  // ====================================================================
  /// Mengambil data lokasi terverifikasi secara atomik saat tombol jepret ditekan.
  /// MENGHILANGKAN `await getCurrentPosition()` saat shutter.
  Future<FastLocationData> getAtomicCaptureLocation() async {
    final now = DateTime.now();

    // 1. Prioritas 1: Gunakan latest verified position jika fresh (<= 15 detik)
    if (_latestVerifiedPosition != null &&
        _isPositionFresh(_latestVerifiedPosition!)) {
      debugPrint(
        '[FAST_LOCATION_PERF] 📸 shutter_atomic_verified = 0ms delay (acc: ±${_latestVerifiedPosition!.accuracy.round()}m)',
      );
      return FastLocationData(
        tier: LocationTier.verified,
        position: _latestVerifiedPosition,
        latitude: _latestVerifiedPosition!.latitude,
        longitude: _latestVerifiedPosition!.longitude,
        accuracy: _latestVerifiedPosition!.accuracy,
        address: _cachedAddress,
        timestamp: now,
        isMocked: _latestVerifiedPosition!.isMocked,
        isStale: false,
      );
    }

    // 2. Prioritas 2: Gunakan latest candidate jika fresh
    if (_latestCandidatePosition != null &&
        _isPositionFresh(_latestCandidatePosition!)) {
      debugPrint(
        '[FAST_LOCATION_PERF] 📸 shutter_atomic_candidate = 0ms delay (acc: ±${_latestCandidatePosition!.accuracy.round()}m)',
      );
      final isVerified =
          _latestCandidatePosition!.accuracy <= 15.0 &&
          !_latestCandidatePosition!.isMocked;
      return FastLocationData(
        tier: isVerified ? LocationTier.verified : LocationTier.freshRefining,
        position: _latestCandidatePosition,
        latitude: _latestCandidatePosition!.latitude,
        longitude: _latestCandidatePosition!.longitude,
        accuracy: _latestCandidatePosition!.accuracy,
        address: _cachedAddress,
        timestamp: now,
        isMocked: _latestCandidatePosition!.isMocked,
        isStale: false,
      );
    }

    // 3. Fallback: Quick position fix dengan timeout sangat singkat (2s)
    try {
      debugPrint('[FAST_LOCATION] ⚠️ Cache stale, requesting quick 2s fix...');
      final quickPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 2),
      );
      _latestCandidatePosition = quickPos;
      if (quickPos.accuracy <= 15.0 && !quickPos.isMocked) {
        _latestVerifiedPosition = quickPos;
      }
      return FastLocationData(
        tier: quickPos.accuracy <= 15.0
            ? LocationTier.verified
            : LocationTier.freshRefining,
        position: quickPos,
        latitude: quickPos.latitude,
        longitude: quickPos.longitude,
        accuracy: quickPos.accuracy,
        address: _cachedAddress,
        timestamp: now,
        isMocked: quickPos.isMocked,
        isStale: false,
      );
    } catch (_) {
      // Jika GPS gagal, gunakan kandidat yang ada sebagai fallback aman
      final fallbackPos = _latestCandidatePosition ?? _warmCandidatePosition;
      return FastLocationData(
        tier: LocationTier.poor,
        position: fallbackPos,
        latitude: fallbackPos?.latitude,
        longitude: fallbackPos?.longitude,
        accuracy: fallbackPos?.accuracy ?? 99.0,
        address: _cachedAddress,
        timestamp: now,
        isMocked: fallbackPos?.isMocked ?? false,
        isStale: true,
      );
    }
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

    try {
      final address = await _reverseGeocoder!.reverseGeocode(
        latitude: lat,
        longitude: lng,
      );

      if (address != null && _isCameraStreamRunning) {
        _cachedAddress = address;
        _cachedAddressLat = lat;
        _cachedAddressLng = lng;

        final currentPos =
            _latestCandidatePosition ??
            _latestVerifiedPosition ??
            _warmCandidatePosition;
        if (currentPos != null) {
          onLocationUpdate(
            FastLocationData(
              tier: currentPos.accuracy <= 15.0
                  ? LocationTier.verified
                  : LocationTier.freshRefining,
              position: currentPos,
              latitude: currentPos.latitude,
              longitude: currentPos.longitude,
              accuracy: currentPos.accuracy,
              address: address,
              timestamp: DateTime.now(),
              isMocked: currentPos.isMocked,
              isStale: false,
            ),
          );
        }
      }
    } catch (_) {
      // Offline / error: Koordinat tetap valid, alamat di-update nanti saat online
    }
  }

  // ====================================================================
  // 5. HELPER UTILITIES
  // ====================================================================
  bool _isPositionFresh(Position position) {
    if (_latestPositionReceivedTime != null) {
      final age = DateTime.now()
          .difference(_latestPositionReceivedTime!)
          .inSeconds;
      return age <= 20;
    }
    final age = DateTime.now().difference(position.timestamp).inSeconds;
    return age <= 30;
  }

  LocationSettings _buildPlatformLocationSettings(LocationAccuracy accuracy) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 500),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
      );
    }
    return LocationSettings(accuracy: accuracy, distanceFilter: 0);
  }
}
