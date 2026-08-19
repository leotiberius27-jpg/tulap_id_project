import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/di/injection_container.dart';
import 'app/presentation/main_shell.dart';
import 'core/sync/background_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/usecases/get_current_session.dart';
import 'features/auth/presentation/pages/login_page.dart';

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
///
/// Dibungkus `runZonedGuarded` + `ErrorWidget.builder` khusus rilis:
/// TIDAK ada layanan crash-reporting terpasang (belum ada keputusan
/// vendor), jadi ini murni jaring pengaman terakhir supaya pengguna
/// asli di lapangan tidak pernah melihat red screen of death Flutter
/// atau app yang diam-diam force-close - error tetap di-log ke
/// `debugPrint` untuk sekarang, ganti dengan crash-reporting service
/// sungguhan begitu ada.
/// ----------------------------------------------------------------------
Future<void> main() async {
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ReleaseErrorFallback();
  }

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // WatermarkOverlay memformat tanggal dengan locale 'id_ID' - tanpa
    // ini, DateFormat('...', 'id_ID') melempar LocaleDataException setiap
    // kali overlay kamera geotag dibangun.
    await initializeDateFormatting('id_ID', null);

    await initDependencies();

    sl<BackgroundSyncService>().start();

    runApp(const TulapApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class _ReleaseErrorFallback extends StatelessWidget {
  const _ReleaseErrorFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'Terjadi kesalahan. Coba tutup dan buka ulang aplikasi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

class TulapApp extends StatelessWidget {
  const TulapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tulap.id',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// AuthGate
/// ----------------------------------------------------------------------
/// Titik keputusan rute awal (Bagian 8 Mobile Sitemap: `Login ->
/// Beranda`). Memeriksa apakah ada sesi tersimpan (token + profil user
/// di flutter_secure_storage, lihat AuthLocalDataSource) TANPA
/// panggilan network - jika ada, user langsung masuk ke MainShell
/// (sesi sebelumnya masih berlaku); jika tidak, ke Login. Dipakai juga
/// dari AccountPage sebagai tujuan navigasi setelah logout (lihat
/// AccountPage._confirmLogout) - karena itu class ini publik, bukan
/// privat seperti sebelumnya.
/// ----------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          return const MainShell();
        }

        return LoginPage(
          onLoginSuccess: (_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        );
      },
    );
  }
}
