import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/geo/fast_location_service.dart';
import '../../../../core/geo/location_exceptions.dart';

/// LockedGeotagPhoto
/// ----------------------------------------------------------------------
/// Hasil satu kali jepret: file foto + koordinat GPS yang DIKUNCI tepat
/// saat foto selesai diambil. Koordinat tidak ikut berubah meski stream
/// GPS langsung di layar terus bergerak.
/// ----------------------------------------------------------------------
class LockedGeotagPhoto {
  final File file;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final DateTime lockedAt;

  /// Sumber kunci: 'GPS_FRESH' (sampel berumur <= 5 detik saat dikunci)
  /// atau 'GPS_STREAM' (sampel cache lebih lama, maksimal 30 detik).
  final String source;

  const LockedGeotagPhoto({
    required this.file,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.lockedAt,
    required this.source,
    this.altitude,
  });

  String get coordinateText =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

enum QuickGeotagStatus { initializing, ready, capturing, locking, error }

/// GeotagLockPolicy
/// ----------------------------------------------------------------------
/// Aturan murni (tanpa I/O) untuk memilih koordinat yang dikunci dari
/// kumpulan sampel GPS. Dipisah dari controller agar bisa diuji tanpa
/// perangkat.
/// ----------------------------------------------------------------------
class GeotagLockPolicy {
  GeotagLockPolicy._();

  /// Sampel lebih tua dari ini tidak pernah dikunci (anti koordinat basi).
  static const Duration maxSampleAge = Duration(seconds: 30);

  /// Sampel semuda ini dianggap "fix GPS baru".
  static const Duration freshAge = Duration(seconds: 5);

  /// Akurasi (meter) yang cukup untuk kunci instan tanpa menunggu -
  /// sama dengan ambang "GPS Akurat" di layar.
  static const double instantLockAccuracy = 15.0;

  /// Kecepatan jalan kaki (m/s) untuk menghukum sampel lama: sampel
  /// ±5 m berumur 20 detik bisa saja sudah meleset ~30 m bila pekerja
  /// berjalan, jadi tidak otomatis menang dari sampel ±12 m yang baru.
  static const double walkingSpeedMps = 1.5;

  static Duration ageOf(Position pos, DateTime now) {
    final age = now.difference(pos.timestamp);
    return age.isNegative ? Duration.zero : age;
  }

  static bool isUsable(Position pos, DateTime now) =>
      ageOf(pos, now) <= maxSampleAge;

  /// Ketidakpastian efektif (meter): akurasi sampel + jarak yang mungkin
  /// sudah ditempuh sejak sampel itu diambil.
  static double effectiveError(Position pos, DateTime now) =>
      pos.accuracy + ageOf(pos, now).inMilliseconds / 1000 * walkingSpeedMps;

  /// Sampel dengan ketidakpastian efektif terkecil, atau null bila tidak
  /// ada sampel yang cukup baru.
  static Position? selectBest(Iterable<Position> samples, DateTime now) {
    Position? best;
    var bestError = double.infinity;
    for (final s in samples) {
      if (!isUsable(s, now)) continue;
      final error = effectiveError(s, now);
      if (error < bestError) {
        best = s;
        bestError = error;
      }
    }
    return best;
  }

  static bool isInstantLockable(Position pos, DateTime now) =>
      ageOf(pos, now) <= freshAge && pos.accuracy <= instantLockAccuracy;

  /// Karena kunci kini dipilih dari banyak sampel, satu sampel mock di
  /// jendela kunci cukup untuk menolak - sampel mock tidak boleh lolos
  /// hanya karena bukan sampel "terbaik".
  static bool containsMocked(Iterable<Position> samples, DateTime now) =>
      samples.any((s) => s.isMocked && isUsable(s, now));
}

/// QuickGeotagController
/// ----------------------------------------------------------------------
/// Modul "Foto + Kunci GPS": membuka kamera hardware bawaan perangkat
/// (lewat `image_picker`, intent kamera native - sengaja tidak memakai
/// live `CameraPreview` CameraX yang diketahui rusak di chipset Unisoc),
/// lalu langsung mengunci koordinat GPS terkini begitu foto kembali.
///
/// Strategi instant-lock:
/// 1. Warm-up: sejak halaman dibuka, cache lokasi (warm-up global
///    FastLocationService + last known) dipakai sebagai jangkar instan,
///    dan stream fused 1 detik terus mengisi buffer sampel.
/// 2. Saat foto kembali: bila buffer sudah punya sampel <= 5 detik dan
///    <= 15 m, kunci SEKETIKA (0 ms menunggu).
/// 3. Bila belum: last known + fix baru diminta paralel, stream tetap
///    mengalir; maksimal 2,5 detik kemudian sampel terbaik yang ada
///    langsung dikunci - tidak pernah menunggu satelit tanpa batas.
/// ----------------------------------------------------------------------
class QuickGeotagController extends ChangeNotifier {
  QuickGeotagController({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  StreamSubscription<Position>? _positionSub;

  /// Interval stream rapat. Tanpa ini geolocator Android memakai default
  /// 5 detik - penyebab utama posisi "hangat" yang sudah tertinggal.
  static const Duration _streamInterval = Duration(seconds: 1);

  /// Batas maksimal menunggu fix yang lebih baik setelah jepret.
  static const Duration _lockWindow = Duration(milliseconds: 2500);

  static const int _maxBufferedSamples = 40;

  QuickGeotagStatus _status = QuickGeotagStatus.initializing;
  QuickGeotagStatus get status => _status;

  Position? _livePosition;
  Position? get livePosition => _livePosition;

  LockedGeotagPhoto? _result;
  LockedGeotagPhoto? get result => _result;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isBusy =>
      _status == QuickGeotagStatus.capturing ||
      _status == QuickGeotagStatus.locking;

  /// Sampel GPS terbaru (<= 30 detik) - kandidat koordinat yang dikunci.
  final List<Position> _samples = [];

  /// Aktif hanya selama jendela kunci; diselesaikan begitu sampel yang
  /// cukup akurat masuk sehingga kunci tidak perlu menunggu batas waktu.
  Completer<void>? _goodFixWaiter;

  bool _disposed = false;

  Future<void> start() async {
    _setStatus(QuickGeotagStatus.initializing);
    try {
      await FastLocationService.instance.checkAndRequestPermissions();
    } on LocationServiceDisabledException {
      return _fail('GPS perangkat mati. Aktifkan Lokasi lalu coba lagi.');
    } on PermissionDeniedException {
      return _fail('Izin lokasi ditolak. Izinkan akses lokasi untuk geotag.');
    } on LocationPermissionDeniedForeverException catch (e) {
      return _fail(e.toString());
    } catch (e) {
      return _fail('Gagal memeriksa izin lokasi: $e');
    }

    unawaited(_seedFromCache());
    await _startStream();

    _errorMessage = null;
    _setStatus(QuickGeotagStatus.ready);
  }

  /// Buka kamera hardware -> simpan foto -> kunci koordinat GPS terkini.
  Future<void> captureAndLock() async {
    if (isBusy) return;
    _errorMessage = null;
    _setStatus(QuickGeotagStatus.capturing);

    // Stream bisa berhenti bila sempat error (mis. GPS dimatikan lalu
    // dinyalakan lagi) - hidupkan ulang agar sampel terus mengalir
    // selama user membidik.
    if (_positionSub == null) await _startStream();

    final XFile? shot;
    try {
      shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );
    } catch (e) {
      return _fail('Kamera tidak dapat dibuka: $e', keepReady: true);
    }

    if (shot == null) {
      // User menutup kamera tanpa memotret - bukan error.
      _setStatus(QuickGeotagStatus.ready);
      return;
    }

    _setStatus(QuickGeotagStatus.locking);
    final lockedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final (position, source) = await _lockBestPosition();
    stopwatch.stop();

    if (position == null) {
      return _fail(
        'GPS belum mendapat sinyal. Pindah ke area terbuka lalu jepret ulang.',
        keepReady: true,
      );
    }
    if (position.isMocked ||
        GeotagLockPolicy.containsMocked(_samples, DateTime.now())) {
      return _fail(
        'Lokasi palsu (mock location) terdeteksi. Foto tidak dikunci.',
        keepReady: true,
      );
    }

    final saved = await _persist(File(shot.path), lockedAt);
    _result = LockedGeotagPhoto(
      file: saved,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      lockedAt: lockedAt,
      source: source,
    );
    debugPrint(
      '[QUICK_GEOTAG] 🔒 locked ${_result!.coordinateText} '
      '±${position.accuracy.toStringAsFixed(1)}m via $source '
      'in ${stopwatch.elapsedMilliseconds}ms -> ${saved.path}',
    );
    _setStatus(QuickGeotagStatus.ready);
  }

  void clearResult() {
    _result = null;
    _errorMessage = null;
    _notify();
  }

  // ====================================================================
  // WARM-UP
  // ====================================================================

  /// Jangkar instan (milidetik): posisi dari warm-up global aplikasi dan
  /// last known milik fused provider, sebelum sampel stream pertama tiba.
  Future<void> _seedFromCache() async {
    final warm = FastLocationService.instance.latestCandidatePosition;
    if (warm != null) _addSample(warm);
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) _addSample(lastKnown);
    } catch (e) {
      debugPrint('[QUICK_GEOTAG] last known unavailable: $e');
    }
  }

  Future<void> _startStream() async {
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(
      _addSample,
      onError: (Object e) {
        debugPrint('[QUICK_GEOTAG] stream error: $e');
        _positionSub?.cancel();
        _positionSub = null;
      },
      onDone: () => _positionSub = null,
    );
  }

  /// Android: geolocator memakai FusedLocationProviderClient (gabungan
  /// GPS + Wi-Fi + seluler) selama Google Play Services tersedia dan
  /// `forceLocationManager` false - TIDAK memaksa GPS satelit murni.
  /// `LocationAccuracy.best` dipetakan ke PRIORITY_HIGH_ACCURACY.
  static LocationSettings _locationSettings({Duration? timeLimit}) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: _streamInterval,
        forceLocationManager: false,
        timeLimit: timeLimit,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      timeLimit: timeLimit,
    );
  }

  void _addSample(Position pos) {
    final now = DateTime.now();
    if (!GeotagLockPolicy.isUsable(pos, now)) return;

    _samples
      ..add(pos)
      ..removeWhere((s) => !GeotagLockPolicy.isUsable(s, now));
    if (_samples.length > _maxBufferedSamples) {
      _samples.removeRange(0, _samples.length - _maxBufferedSamples);
    }

    // Cache bisa datang setelah sampel stream - jangan mundurkan tampilan.
    final live = _livePosition;
    if (live == null || !pos.timestamp.isBefore(live.timestamp)) {
      _livePosition = pos;
      _notify();
    }

    if (GeotagLockPolicy.isInstantLockable(pos, now)) {
      _completeWaiter();
    }
  }

  // ====================================================================
  // LOCK
  // ====================================================================

  Future<(Position?, String)> _lockBestPosition() async {
    // 1. Kunci instan dari buffer bila sudah cukup baru & akurat.
    final cached = GeotagLockPolicy.selectBest(_samples, DateTime.now());
    if (cached != null &&
        GeotagLockPolicy.isInstantLockable(cached, DateTime.now())) {
      return _withSource(cached);
    }

    // 2. Jendela singkat: stream terus mengalir, ditambah last known dan
    //    fix baru yang diminta paralel. Selesai lebih awal begitu ada
    //    sampel akurat atau fix baru tiba.
    final waiter = Completer<void>();
    _goodFixWaiter = waiter;
    unawaited(_requestParallelFix());
    await waiter.future.timeout(_lockWindow, onTimeout: () {});
    _goodFixWaiter = null;

    // 3. Kunci sampel terbaik yang ada - akurasi lemah pun tetap dikunci
    //    daripada membuat user menunggu satelit.
    final best = GeotagLockPolicy.selectBest(_samples, DateTime.now());
    return best == null ? (null, '') : _withSource(best);
  }

  Future<void> _requestParallelFix() async {
    await Future.wait([
      () async {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) _addSample(last);
        } catch (e) {
          debugPrint('[QUICK_GEOTAG] last known failed: $e');
        }
      }(),
      () async {
        try {
          final fresh = await Geolocator.getCurrentPosition(
            locationSettings: _locationSettings(timeLimit: _lockWindow),
          );
          _addSample(fresh);
          // Fix baru = estimasi terkini fused provider; menunggu lebih
          // lama jarang memperbaikinya dalam hitungan detik.
          _completeWaiter();
        } catch (e) {
          debugPrint('[QUICK_GEOTAG] fresh fix failed: $e');
        }
      }(),
    ]);
  }

  (Position, String) _withSource(Position pos) {
    final age = GeotagLockPolicy.ageOf(pos, DateTime.now());
    return (pos, age <= GeotagLockPolicy.freshAge ? 'GPS_FRESH' : 'GPS_STREAM');
  }

  void _completeWaiter() {
    final waiter = _goodFixWaiter;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
  }

  /// Pindahkan foto dari cache sementara image_picker ke direktori
  /// dokumen aplikasi agar tidak ikut terhapus saat cache dibersihkan.
  Future<File> _persist(File temp, DateTime at) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'quick_geotag'));
      await dir.create(recursive: true);
      final name = 'GEO_${DateFormat('yyyyMMdd_HHmmss').format(at)}.jpg';
      return await temp.copy(p.join(dir.path, name));
    } catch (e) {
      debugPrint('[QUICK_GEOTAG] persist failed, keeping temp file: $e');
      return temp;
    }
  }

  void _fail(String message, {bool keepReady = false}) {
    _errorMessage = message;
    _setStatus(keepReady ? QuickGeotagStatus.ready : QuickGeotagStatus.error);
  }

  void _setStatus(QuickGeotagStatus s) {
    _status = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _completeWaiter();
    _positionSub?.cancel();
    super.dispose();
  }
}
