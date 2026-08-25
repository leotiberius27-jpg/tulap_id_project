import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/di/injection_container.dart';
import 'app/presentation/main_shell.dart';
import 'core/session/auth_session_manager.dart';
import 'core/sync/background_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/domain/usecases/get_current_session.dart';
import 'features/auth/presentation/pages/welcome_page.dart';

/// main.dart
/// ----------------------------------------------------------------------
/// Urutan inisialisasi WAJIB seperti ini:
///   1. WidgetsFlutterBinding - agar plugin native (sqflite, camera,
///      geolocator) siap dipanggil sebelum widget tree dibangun.
///   2. initDependencies() - merangkai seluruh service locator.
///   3. Preload theme mode dari local secure storage (mencegah flash theme).
///   4. Mulai BackgroundSyncService.
///   5. runApp()
/// ----------------------------------------------------------------------
Future<void> main() async {
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ReleaseErrorFallback();
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // WatermarkOverlay memformat tanggal dengan locale 'id_ID'
      await initializeDateFormatting('id_ID', null);

      await initDependencies();

      // Memuat preferensi tema sebelum runApp untuk mencegah flash
      await sl<ThemeController>().loadTheme();

      sl<BackgroundSyncService>().start();

      runApp(const TulapApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
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
    final themeController = sl<ThemeController>();

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tulap.id',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          home: const AuthGate(),
        );
      },
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
      future: sl<AuthSessionManager>().loadInitialSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const MainShell();
        }

        return WelcomePage(
          onLoginSuccess: (_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          },
        );
      },
    );
  }
}
