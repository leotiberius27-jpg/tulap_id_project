import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// LocationFusionEngine
/// ----------------------------------------------------------------------
/// Filter Kalman 2D (posisi saja) yang menggabungkan setiap fix GPS/fused
/// menjadi satu estimasi posisi + ketidakpastian - teknik yang sama dengan
/// yang dipakai aplikasi GPS kamera / survei profesional:
///
/// 1. FUSI BERBOBOT AKURASI: tiap sampel dibobot 1/akurasi², jadi satu fix
///    ±40 m tidak bisa merusak estimasi ±6 m, dan saat petugas berdiri
///    diam beberapa detik, beberapa fix ±10 m menyatu jadi estimasi yang
///    lebih rapat daripada fix tunggal mana pun.
/// 2. KETIDAKPASTIAN TUMBUH SEIRING UMUR: estimasi tanpa fix baru
///    dianggap bisa sudah meleset `assumedSpeedMps` per detik (orang
///    berjalan). Fix ±5 m berumur 20 detik = ±35 m, bukan ±5 m - inilah
///    yang mencegah koordinat lama (mis. di rumah) tercap ke foto di
///    lokasi lapangan.
/// 3. PENOLAKAN OUTLIER: lompatan yang mustahil secara fisik (multipath,
///    pantulan gedung, glitch Wi-Fi positioning) ditolak. Jika 3 sampel
///    berturut-turut tetap "melompat", itu perpindahan nyata (mis. naik
///    kendaraan) dan filter di-reset ke posisi baru.
///
/// Semua waktu memakai `observedAt` (jam lokal saat sampel DITERIMA),
/// bukan `Position.timestamp`, agar kebal terhadap jam ponsel yang
/// meleset dari waktu GPS. Untuk last-known position, pemanggil
/// mengoper timestamp aslinya sebagai `observedAt` agar umurnya jujur.
///
/// Kelas ini murni (tanpa I/O, tanpa jam global) sehingga bisa diuji unit.
/// ----------------------------------------------------------------------
class LocationFusionEngine {
  LocationFusionEngine({
    this.assumedSpeedMps = 1.5,
    this.maxPlausibleSpeedMps = 70.0,
    this.accuracyFloorMeters = 3.0,
    this.correlationFactor = 0.6,
    this.rejectStreakToReset = 3,
  });

  /// Kecepatan (m/s) yang diasumsikan untuk menumbuhkan ketidakpastian
  /// antar sampel - kecepatan jalan kaki.
  final double assumedSpeedMps;

  /// Kecepatan di atas ini (≈250 km/jam) dianggap mustahil -> outlier.
  final double maxPlausibleSpeedMps;

  /// Akurasi terbaik yang pernah dilaporkan (GPS konsumen ±3 m realistis).
  final double accuracyFloorMeters;

  /// Error GPS antar detik saling berkorelasi (multipath yang sama), jadi
  /// fusi tidak boleh mengklaim lebih baik dari [correlationFactor] ×
  /// akurasi mentah terbaik dalam 10 detik terakhir. Menjaga angka ±m
  /// pada watermark tetap jujur secara forensik.
  final double correlationFactor;

  final int rejectStreakToReset;

  static const double _earthRadius = 6371008.8;
  static const Duration _recentWindow = Duration(seconds: 10);

  double _lat0 = 0, _lng0 = 0, _cosLat0 = 1;
  double _x = 0, _y = 0; // meter timur / utara dari origin
  double _variance = 0; // m²
  DateTime? _stateAt;
  Position? _lastRaw;
  int _sampleCount = 0;
  int _rejectStreak = 0;
  final List<({DateTime at, double accuracy})> _recentRaw = [];

  bool get hasEstimate => _stateAt != null;
  int get sampleCount => _sampleCount;
  DateTime? get estimateObservedAt => _stateAt;

  void reset() {
    _stateAt = null;
    _lastRaw = null;
    _variance = 0;
    _sampleCount = 0;
    _rejectStreak = 0;
    _recentRaw.clear();
  }

  /// Memasukkan satu sampel. Mengembalikan `true` bila sampel dipakai.
  /// Sampel mock, akurasi tidak valid, atau lebih tua dari estimasi saat
  /// ini diabaikan.
  bool addSample(Position sample, {required DateTime observedAt}) {
    if (sample.isMocked) return false;
    final acc = sample.accuracy;
    if (!acc.isFinite || acc <= 0) return false;
    if (!sample.latitude.isFinite || !sample.longitude.isFinite) return false;

    final r = math.max(acc, accuracyFloorMeters);

    if (_stateAt == null) {
      _init(sample, observedAt, r);
      return true;
    }

    final dtMs = observedAt.difference(_stateAt!).inMilliseconds;
    if (dtMs < 0) return false; // sampel basi datang terlambat
    final dt = dtMs / 1000.0;

    final (mx, my) = _project(sample.latitude, sample.longitude);
    final dx = mx - _x;
    final dy = my - _y;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Prediksi: ketidakpastian tumbuh linear sesuai jarak yang mungkin
    // ditempuh. Jika perangkat melaporkan kecepatan nyata (mis. di
    // kendaraan) yang lebih besar, pakai itu.
    final reportedSpeed = sample.speed.isFinite ? sample.speed : 0.0;
    final speed = math.max(assumedSpeedMps, reportedSpeed);
    final predictedSigma = math.sqrt(_variance) + speed * dt;
    final predictedVariance = predictedSigma * predictedSigma;

    // Gate outlier: lompatan di luar 3σ gabungan DAN sisa jarak yang tak
    // terjelaskan ketidakpastian hanya mungkin ditempuh dengan kecepatan
    // mustahil.
    final unexplained = dist - predictedSigma - r;
    final isOutlier =
        dist > 3 * math.sqrt(predictedVariance + r * r) &&
        unexplained / math.max(dt, 0.5) > maxPlausibleSpeedMps;
    if (isOutlier) {
      _rejectStreak++;
      if (_rejectStreak >= rejectStreakToReset) {
        // Bukan glitch - perangkat benar-benar pindah jauh.
        _init(sample, observedAt, r);
        return true;
      }
      return false;
    }
    _rejectStreak = 0;

    // Update Kalman (skalar, isotropik).
    final gain = predictedVariance / (predictedVariance + r * r);
    _x += gain * dx;
    _y += gain * dy;
    _variance = (1 - gain) * predictedVariance;
    _stateAt = observedAt;
    _lastRaw = sample;
    _sampleCount++;
    _pushRecent(observedAt, r);
    return true;
  }

  /// Ketidakpastian (meter, 1σ ~ setara "accuracy" Android) estimasi pada
  /// waktu [now], sudah termasuk pertumbuhan karena umur.
  double? accuracyAt(DateTime now) {
    final stateAt = _stateAt;
    if (stateAt == null) return null;
    final ageS = math.max(0, now.difference(stateAt).inMilliseconds) / 1000.0;
    final sigma = math.sqrt(_variance) + assumedSpeedMps * ageS;
    return math.max(sigma, _honestFloor(stateAt));
  }

  /// Umur estimasi pada waktu [now].
  Duration? ageAt(DateTime now) {
    final stateAt = _stateAt;
    if (stateAt == null) return null;
    final age = now.difference(stateAt);
    return age.isNegative ? Duration.zero : age;
  }

  /// Estimasi terfusi sebagai [Position]. `accuracy` = ketidakpastian
  /// pada saat sampel terakhir diterima (belum termasuk umur - pakai
  /// [accuracyAt] untuk itu). Altitude/heading/speed diambil dari sampel
  /// mentah terakhir.
  Position? get estimate {
    final raw = _lastRaw;
    final stateAt = _stateAt;
    if (raw == null || stateAt == null) return null;
    final (lat, lng) = _unproject(_x, _y);
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: raw.timestamp,
      accuracy: math.max(math.sqrt(_variance), _honestFloor(stateAt)),
      altitude: raw.altitude,
      altitudeAccuracy: raw.altitudeAccuracy,
      heading: raw.heading,
      headingAccuracy: raw.headingAccuracy,
      speed: raw.speed,
      speedAccuracy: raw.speedAccuracy,
      floor: raw.floor,
      isMocked: false,
    );
  }

  void _init(Position s, DateTime observedAt, double r) {
    _lat0 = s.latitude;
    _lng0 = s.longitude;
    _cosLat0 = math.cos(_lat0 * math.pi / 180);
    _x = 0;
    _y = 0;
    _variance = r * r;
    _stateAt = observedAt;
    _lastRaw = s;
    _sampleCount = 1;
    _rejectStreak = 0;
    _recentRaw.clear();
    _pushRecent(observedAt, r);
  }

  void _pushRecent(DateTime at, double accuracy) {
    _recentRaw.add((at: at, accuracy: accuracy));
    _recentRaw.removeWhere((e) => at.difference(e.at) > _recentWindow);
  }

  double _honestFloor(DateTime reference) {
    var best = double.infinity;
    for (final e in _recentRaw) {
      if (reference.difference(e.at) <= _recentWindow && e.accuracy < best) {
        best = e.accuracy;
      }
    }
    if (!best.isFinite) return accuracyFloorMeters;
    return math.max(accuracyFloorMeters, best * correlationFactor);
  }

  (double, double) _project(double lat, double lng) {
    final rad = math.pi / 180;
    return (
      (lng - _lng0) * rad * _earthRadius * _cosLat0,
      (lat - _lat0) * rad * _earthRadius,
    );
  }

  (double, double) _unproject(double x, double y) {
    final deg = 180 / math.pi;
    return (
      _lat0 + (y / _earthRadius) * deg,
      _lng0 + (x / (_earthRadius * _cosLat0)) * deg,
    );
  }
}
