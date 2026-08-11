import 'package:connectivity_plus/connectivity_plus.dart';

/// NetworkInfo
/// ----------------------------------------------------------------------
/// Abstraksi tipis di atas package connectivity_plus untuk mengecek
/// apakah perangkat sedang online. Dipakai oleh BackgroundSyncService
/// untuk memutuskan kapan proses sinkronisasi outbox boleh berjalan.
///
/// PENTING: hasil `isConnected` hanya menandakan ADA koneksi jaringan
/// (WiFi/data seluler tersambung), BUKAN jaminan internet benar-benar
/// bisa diakses (mis. WiFi kantor tanpa internet). Untuk kepastian
/// lebih tinggi, SyncLocalDataSource tetap menangani kegagalan request
/// aktual sebagai sinyal "belum benar-benar online" dan mengembalikan
/// item ke antrian.
/// ----------------------------------------------------------------------
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream yang bisa didengarkan BackgroundSyncService untuk memicu
  /// sinkronisasi otomatis begitu koneksi kembali tersedia.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => !result.contains(ConnectivityResult.none),
    );
  }
}
