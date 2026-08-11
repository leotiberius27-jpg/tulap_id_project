import 'dart:async';
import '../../features/sync_queue/domain/usecases/process_sync_queue.dart';
import '../network/network_info.dart';

/// BackgroundSyncService
/// ----------------------------------------------------------------------
/// Service tingkat aplikasi (bukan bagian dari satu fitur spesifik) yang
/// memicu `ProcessSyncQueue` secara otomatis pada dua kondisi:
///   1. Begitu koneksi internet kembali tersedia (event-driven, respons
///      cepat - selaras dengan janji "Sinkronisasi (saat online)").
///   2. Polling berkala sebagai jaring pengaman, untuk kasus event
///      konektivitas tidak terdeteksi dengan baik oleh OS.
///
/// Service ini di-inisialisasi SEKALI di awal aplikasi (mis. lewat
/// dependency injection container) dan berjalan sepanjang app aktif.
/// ----------------------------------------------------------------------
class BackgroundSyncService {
  final ProcessSyncQueue _processSyncQueue;
  final NetworkInfo _networkInfo;

  static const Duration _fallbackPollingInterval = Duration(minutes: 2);

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _pollingTimer;
  bool _isSyncing = false;

  BackgroundSyncService({
    required ProcessSyncQueue processSyncQueue,
    required NetworkInfo networkInfo,
  })  : _processSyncQueue = processSyncQueue,
        _networkInfo = networkInfo;

  void start() {
    // Trigger 1: event-driven, begitu koneksi berubah jadi online
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          _runSyncSafely();
        }
      },
    );

    // Trigger 2: jaring pengaman berkala
    _pollingTimer = Timer.periodic(_fallbackPollingInterval, (_) {
      _runSyncSafely();
    });

    // Jalankan sekali di awal untuk membersihkan antrian yang mungkin
    // sudah menumpuk sejak sesi sebelumnya.
    _runSyncSafely();
  }

  /// Dipanggil manual dari Sync Center saat user menekan tombol
  /// "Coba Kirim Lagi" di level global (bukan retry per-item).
  Future<void> triggerManualSync() => _runSyncSafely();

  Future<void> _runSyncSafely() async {
    // Mencegah proses sync tumpang tindih jika trigger event & polling
    // kebetulan terjadi bersamaan.
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _processSyncQueue();
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _pollingTimer?.cancel();
  }
}
