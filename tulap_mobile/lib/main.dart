import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/di/injection_container.dart';
import 'app/presentation/main_shell.dart';
import 'core/geo/fast_location_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_controller.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/session/auth_session_manager.dart';
import 'core/sync/background_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/assistant/presentation/widgets/tula_overlay.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'firebase_options.dart';

/// main.dart
/// ----------------------------------------------------------------------
/// Urutan inisialisasi WAJIB seperti ini:
///   1. WidgetsFlutterBinding - agar plugin native (sqflite, camera,
///      geolocator) siap dipanggil sebelum widget tree dibangun.
///   2. Firebase.initializeApp() - sebelum service lain yang mungkin
///      bergantung padanya (mis. push notification di masa depan).
///   3. initDependencies() - merangkai seluruh service locator.
///   4. Preload theme mode & language dari local secure storage (mencegah flash).
///   5. Mulai BackgroundSyncService, FastLocationService warm-up, &
///      PushNotificationService (FCM) - listener sesinya dipasang SEBELUM
///      runApp() supaya sesi lama yang dipulihkan AuthGate (setelah
///      runApp()) tetap tertangkap dengan benar.
///   6. runApp()
/// ----------------------------------------------------------------------
Future<void> main() async {
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ReleaseErrorFallback();
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // WatermarkOverlay & App memformat tanggal dengan locale 'id_ID' dan 'en_US'
      await initializeDateFormatting('id_ID', null);
      await initializeDateFormatting('en_US', null);

      await initDependencies();

      // Memuat preferensi tema & bahasa sebelum runApp untuk mencegah flash
      await sl<ThemeController>().loadTheme();
      await sl<LanguageController>().loadLanguage();

      sl<BackgroundSyncService>().start();
      FastLocationService.instance.startWarmUp();
      await sl<PushNotificationService>().init();

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
    final languageController = sl<LanguageController>();

    return ListenableBuilder(
      listenable: Listenable.merge([themeController, languageController]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: TulaOverlay.navigatorKey,
          title: 'Tulap.id',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          locale: languageController.currentLocale,
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // TulaOverlay dipasang SEKALI di sini agar floating assistant
          // Tula berlaku untuk seluruh Navigator (MainShell & semua
          // halaman fullscreen yang di-push di atasnya) tanpa duplikasi
          // floating button di nested navigator manapun.
          builder: (context, child) =>
              TulaOverlay(child: child ?? const SizedBox.shrink()),
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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<dynamic> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = sl<AuthSessionManager>().loadInitialSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.data != null) {
          return const MainShell();
        }

        return LoginPage(
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
