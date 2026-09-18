import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'static_map_thumbnail.dart';

/// StaticMapFetcher
/// ----------------------------------------------------------------------
/// Mengunduh byte gambar peta statis nyata (Google Static Maps jika API key
/// tersedia, atau fallback OpenStreetMap tanpa key - lihat
/// StaticMapThumbnail) untuk dibakar sebagai mini-map SUNGGUHAN di
/// watermark foto, menggantikan grafis prosedural (grid/radar/pin) yang
/// dipakai MiniMapRenderer saat byte ini tidak tersedia.
///
/// PENTING - Dio TERPISAH dari client API backend NestJS aplikasi:
/// client API utama (lihat injection_container.dart) memasang interceptor
/// Authorization Bearer JWT pengguna secara otomatis ke SETIAP request -
/// memakainya di sini akan mengirim token sesi pengguna ke Google/OSM.
/// Instance Dio polos di bawah ini sengaja tidak pernah menyentuh client itu.
///
/// NON-BLOCKING BY DESIGN: dipanggil sebagai Future yang TIDAK di-await di
/// titik shutter (lihat GeotagCameraRepositoryImpl) - hasilnya baru
/// ditunggu (dengan timeout ketat) tepat sebelum kompositor merender panel,
/// setelah `controller.takePicture()` sudah selesai. Jaringan lambat/mati
/// TIDAK PERNAH menunda jepretan kamera, hanya membuat compositor jatuh ke
/// peta prosedural seperti sedia kala.
/// ----------------------------------------------------------------------
class StaticMapFetcher {
  static final StaticMapFetcher instance = StaticMapFetcher._internal();

  /// Dimatikan otomatis selama widget test (lihat test/flutter_test_config.dart)
  /// - `flutter_test` TIDAK PERNAH menunggu I/O jaringan nyata di dalam
  /// `pumpWidget()` biasa (bukan `pumpAndSettle`/`runAsync`), jadi Timer
  /// internal `.timeout()` di bawah bisa tetap "pending" begitu fungsi
  /// test selesai - memicu assertion fatal framework
  /// "A Timer is still pending even after the widget tree was disposed."
  /// TIDAK memengaruhi aplikasi nyata sama sekali (tetap `true` di luar
  /// test runner).
  static bool debugNetworkEnabled = true;

  StaticMapFetcher._internal() : _dio = Dio(), _urlBuilder = StaticMapThumbnail();

  StaticMapFetcher.test({required Dio dio, StaticMapThumbnail? urlBuilder})
      : _dio = dio,
        _urlBuilder = urlBuilder ?? StaticMapThumbnail();

  final Dio _dio;
  final StaticMapThumbnail _urlBuilder;

  Uint8List? _cachedBytes;
  double? _cachedLat;
  double? _cachedLng;

  /// [cancelToken] opsional - dibatalkan pemanggil (mis. saat widget UI
  /// yang memintanya di-dispose sebelum respons datang) supaya request Dio
  /// yang masih berjalan benar-benar berhenti, bukan cuma diabaikan -
  /// mencegah Timer internal `.timeout()` di bawah tetap "pending" setelah
  /// widget/tree pemanggilnya sudah tidak ada lagi (fatal di widget test
  /// Flutter: "A Timer is still pending even after the widget tree was
  /// disposed").
  Future<Uint8List?> fetch({
    required double latitude,
    required double longitude,
    int width = 320,
    int height = 320,
    int zoom = 16,
    Duration timeout = const Duration(seconds: 3),
    CancelToken? cancelToken,
  }) async {
    if (!debugNetworkEnabled) return null;

    if (_cachedBytes != null && _cachedLat != null && _cachedLng != null) {
      final dLat = (latitude - _cachedLat!).abs();
      final dLng = (longitude - _cachedLng!).abs();
      if (dLat < 0.0004 && dLng < 0.0004) {
        return _cachedBytes;
      }
    }

    try {
      final url = _urlBuilder.buildUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        zoom: zoom,
      );
      final response = await _dio
          .get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelToken,
          )
          .timeout(timeout);
      final data = response.data;
      if (data == null || data.isEmpty) return null;

      final bytes = Uint8List.fromList(data);
      _cachedBytes = bytes;
      _cachedLat = latitude;
      _cachedLng = longitude;
      return bytes;
    } catch (_) {
      // Offline / timeout / DNS gagal / kuota API habis: kembalikan null
      // secara diam-diam - pemanggil (MiniMapRenderer) sudah punya
      // fallback grafis prosedural yang jujur untuk kasus ini.
      return null;
    }
  }
}
