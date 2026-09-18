import 'dart:async';
import 'package:tulap_mobile/core/geo/static_map_fetcher.dart';

/// flutter_test_config.dart
/// ----------------------------------------------------------------------
/// Dijalankan otomatis oleh test runner SEBELUM setiap file test di folder
/// ini (konvensi package `test`). Menonaktifkan panggilan jaringan nyata
/// StaticMapFetcher (dipakai RealMiniMapPreview untuk thumbnail peta nyata
/// di GeotagPhotoLocationCard & CameraStampPreview template GPS Map
/// Camera) selama widget test - `flutter_test` tidak pernah menunggu I/O
/// jaringan nyata di dalam `pumpWidget()` biasa, jadi request yang
/// dibiarkan berjalan akan tetap punya Timer `.timeout()` "pending" saat
/// fungsi test selesai, memicu assertion fatal framework "A Timer is
/// still pending even after the widget tree was disposed." Tidak
/// memengaruhi aplikasi nyata sama sekali - hanya aktif di bawah test
/// runner ini.
/// ----------------------------------------------------------------------
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  StaticMapFetcher.debugNetworkEnabled = false;
  await testMain();
}
