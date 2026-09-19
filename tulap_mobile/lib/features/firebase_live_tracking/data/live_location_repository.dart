import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu titik koordinat lapangan yang sedang/pernah dipancarkan secara
/// real-time oleh seorang user.
class LiveLocationPoint {
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  const LiveLocationPoint({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  factory LiveLocationPoint.fromFirestore(
    String userId,
    Map<String, dynamic> data,
  ) {
    final geo = data['position'] as GeoPoint?;
    final ts = data['updatedAt'] as Timestamp?;
    return LiveLocationPoint(
      userId: userId,
      latitude: geo?.latitude ?? 0,
      longitude: geo?.longitude ?? 0,
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      updatedAt: ts?.toDate(),
    );
  }
}

/// LiveLocationRepository
/// ----------------------------------------------------------------------
/// Modul FIRESTORE BERDIRI SENDIRI (standalone) untuk menulis & membaca
/// koordinat lokasi lapangan SECARA REAL-TIME - TERPISAH dari
/// `FirestoreSyncService` di backend
/// (`tulap_backend/src/infrastructure/firestore`), yang hanya mencermin-
/// kan laporan/foto SETELAH tersimpan di PostgreSQL (async, one-shot per
/// submit). Modul ini menulis LANGSUNG dari klien Flutter selama sesi
/// lapangan berlangsung, jadi posisi bisa dipantau real-time lewat
/// `.snapshots()` tanpa menunggu submit.
///
/// Skema Firestore:
///   `live_locations/{userId}`
///     - `position`  : GeoPoint (lat, lng)
///     - `accuracy`  : number (meter), nullable
///     - `speed`     : number (m/s), nullable
///     - `heading`   : number (derajat), nullable
///     - `updatedAt` : Timestamp (server-side, `FieldValue.serverTimestamp()`)
///
/// SATU dokumen per user (bukan koleksi log tak-terbatas) - dokumen ini
/// SELALU di-overwrite (`merge: true`) dengan posisi terbaru, cocok
/// untuk use-case "di mana posisi petugas SEKARANG", bukan riwayat
/// perjalanan penuh. Firestore Security Rules perlu membatasi agar user
/// hanya bisa menulis dokumennya sendiri (`request.auth.uid == userId`)
/// sebelum fitur ini dipakai di produksi.
/// ----------------------------------------------------------------------
class LiveLocationRepository {
  LiveLocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'live_locations';

  CollectionReference<Map<String, dynamic>> get _liveLocations =>
      _firestore.collection(_collection);

  /// Menulis satu titik koordinat terbaru untuk [userId]. Dipanggil
  /// berulang dari listener GPS (lihat `LiveLocationTrackingService`) -
  /// setiap panggilan meng-overwrite dokumen yang sama, sehingga siapa
  /// pun yang men-subscribe `watchLocation(userId)` menerima posisi
  /// terkini dalam hitungan detik.
  Future<void> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) {
    return _liveLocations.doc(userId).set({
      'position': GeoPoint(latitude, longitude),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream real-time posisi terkini satu user - dipakai mis. oleh
  /// dashboard supervisor untuk menampilkan titik yang bergerak di peta
  /// tanpa polling manual.
  Stream<LiveLocationPoint?> watchLocation(String userId) {
    return _liveLocations.doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return LiveLocationPoint.fromFirestore(userId, data);
    });
  }

  /// Stream real-time SELURUH petugas yang posisinya pernah tercatat -
  /// dipakai untuk peta sebaran lokasi live (semua titik sekaligus).
  Stream<List<LiveLocationPoint>> watchAllLocations() {
    return _liveLocations.snapshots().map(
      (snap) => snap.docs
          .map((doc) => LiveLocationPoint.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Menghapus dokumen posisi user - dipanggil saat sesi lapangan
  /// selesai/logout agar user tidak tampak "masih di lapangan" selamanya.
  Future<void> clearLocation(String userId) {
    return _liveLocations.doc(userId).delete();
  }
}
