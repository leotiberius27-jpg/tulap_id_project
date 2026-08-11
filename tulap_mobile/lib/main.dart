import 'package:flutter/material.dart';
import 'app/di/injection_container.dart';
import 'core/sync/background_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/usecases/get_current_session.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

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
      home: const _AuthGate(),
    );
  }
}

/// _AuthGate
/// ----------------------------------------------------------------------
/// Titik keputusan rute awal (Bagian 8 Mobile Sitemap: `Login ->
/// Beranda`). Memeriksa apakah ada sesi tersimpan (token + profil user
/// di flutter_secure_storage, lihat AuthLocalDataSource) TANPA
/// panggilan network - jika ada, user langsung masuk ke Beranda
/// (sesi sebelumnya masih berlaku); jika tidak, ke Login.
/// ----------------------------------------------------------------------
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl<GetCurrentSession>()(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const HomePage();
        }

        return LoginPage(
          onLoginSuccess: (_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        );
      },
    );
  }
}
