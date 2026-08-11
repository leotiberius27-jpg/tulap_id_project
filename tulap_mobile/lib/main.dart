import 'package:flutter/material.dart';
import 'app/di/injection_container.dart';
import 'core/sync/background_sync_service.dart';
import 'core/theme/app_theme.dart';

/// main.dart
/// ----------------------------------------------------------------------
/// Urutan inisialisasi WAJIB seperti ini:
///   1. WidgetsFlutterBinding - agar plugin native (sqflite, camera,
///      geolocator) siap dipanggil sebelum widget tree dibangun.
///   2. initDependencies() - merangkai seluruh service locator (lihat
///      injection_container.dart), termasuk membuka koneksi database.
///   3. Mulai BackgroundSyncService - agar antrian outbox yang mungkin
///      masih menumpuk dari sesi sebelumnya langsung diproses begitu
///      app dibuka dan online.
///   4. runApp()
/// ----------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  sl<BackgroundSyncService>().start();

  runApp(const TulapApp());
}

class TulapApp extends StatelessWidget {
  const TulapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tulap.id',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Rute awal sementara - akan diganti dengan flow Login -> Beranda
      // begitu fitur auth & home dibangun di sisi mobile.
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Tulap.id - Beranda menyusul'),
      ),
    );
  }
}
