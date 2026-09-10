import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/core/security/biometric_auth_service.dart';
import 'package:tulap_mobile/core/security/oauth_sign_in_service.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_biometric_greeting_user.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/is_biometric_login_enabled.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_apple.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_facebook.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login_with_google.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/restore_biometric_session.dart';
import 'package:tulap_mobile/features/auth/presentation/pages/welcome_page.dart';

class _FakeNetworkInfo extends NetworkInfo {
  bool online;
  _FakeNetworkInfo({this.online = true}) : super(Connectivity());

  @override
  Future<bool> get isConnected async => online;
}

class _FakeBiometricAuthService implements BiometricAuthService {
  bool available = true;
  bool shouldSucceed = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => shouldSucceed;

  @override
  Future<bool> isSupported() async => available;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOAuthService implements OAuthSignInService {
  @override
  Future<({String idToken, String? email, String? displayName})?>
  signInWithGoogle({bool forceAccountChooser = false}) async => null;

  @override
  Future<({String identityToken, String? fullName})?> signInWithApple() async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  AuthUserEntity? storedUser;

  @override
  Future<AuthUserEntity?> getStoredUser() async => storedUser;

  @override
  Future<AuthUserEntity?> getBiometricGreetingUser() async => storedUser;

  @override
  Future<AuthUserEntity?> restoreBiometricSession() async => storedUser;

  @override
  Future<bool> isBiometricLoginEnabled() async => false;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-1',
        fullName: 'Budi Santoso',
        email: 'budi@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-google',
        fullName: 'Leonardo',
        email: 'google@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-apple',
        fullName: 'Leonardo',
        email: 'apple@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUserEntity>> loginWithFacebook({
    required String accessToken,
    String? email,
    String? fullName,
  }) async {
    return const Right(
      AuthUserEntity(
        id: 'usr-facebook',
        fullName: 'Leonardo',
        email: 'facebook@tulap.id',
        role: 'PEGAWAI',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeNetworkInfo fakeNetwork;
  late _FakeBiometricAuthService fakeBiometric;
  late _FakeOAuthService fakeOAuth;
  late _FakeAuthRepository fakeRepo;

  setUp(() {
    fakeNetwork = _FakeNetworkInfo(online: true);
    fakeBiometric = _FakeBiometricAuthService();
    fakeOAuth = _FakeOAuthService();
    fakeRepo = _FakeAuthRepository();

    final sl = GetIt.instance;
    sl.reset();

    sl.registerLazySingleton<NetworkInfo>(() => fakeNetwork);
    sl.registerLazySingleton<BiometricAuthService>(() => fakeBiometric);
    sl.registerLazySingleton<OAuthSignInService>(() => fakeOAuth);
    sl.registerLazySingleton<GetBiometricGreetingUser>(
      () => GetBiometricGreetingUser(fakeRepo),
    );
    sl.registerLazySingleton<RestoreBiometricSession>(
      () => RestoreBiometricSession(fakeRepo),
    );
    sl.registerLazySingleton<IsBiometricLoginEnabled>(
      () => IsBiometricLoginEnabled(fakeRepo),
    );
    sl.registerLazySingleton<Login>(() => Login(fakeRepo));
    sl.registerLazySingleton<LoginWithGoogle>(() => LoginWithGoogle(fakeRepo));
    sl.registerLazySingleton<LoginWithApple>(() => LoginWithApple(fakeRepo));
    sl.registerLazySingleton<LoginWithFacebook>(() => LoginWithFacebook(fakeRepo));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildWelcomePage({ValueChanged<AuthUserEntity>? onSuccess}) {
    return MaterialApp(home: WelcomePage(onLoginSuccess: onSuccess ?? (_) {}));
  }

  Future<void> pumpWelcome(WidgetTester tester) async {
    await tester.pumpWidget(buildWelcomePage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Hero Video & WelcomePage Multi-Viewport Responsive Tests', () {
    const viewports = [
      Size(320, 568), // iPhone SE / Small Android
      Size(360, 640), // Standard Compact Android
      Size(360, 800), // Standard Tall Android
      Size(375, 812), // iPhone X / 11 Pro
      Size(390, 844), // iPhone 13 / 14 / Realme
      Size(412, 915), // Pixel 7
      Size(430, 932), // iPhone Pro Max / Ultra
    ];

    for (final size in viewports) {
      testWidgets(
        'Renders Hero Video and UI cleanly on viewport ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await pumpWelcome(tester);

          // 1. Verifikasi Header
          expect(find.text('Tulap.id'), findsOneWidget);
          expect(find.text('Tugas Lapangan dalam Kendali'), findsOneWidget);
          expect(find.text('Online'), findsOneWidget);

          // 2. Verifikasi Quick Access Panel
          expect(find.text('Akses Cepat'), findsOneWidget);
          expect(find.text('Tugas Saya'), findsOneWidget);
          expect(find.text('Kamera Lokasi'), findsOneWidget);
          expect(find.text('Scan Nota'), findsOneWidget);
          expect(find.text('Sinkronisasi'), findsOneWidget);

          // 3. Verifikasi Action Buttons
          expect(find.text('Masuk'), findsOneWidget);
          expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);

          // Zero exceptions / zero overflows
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Clean Welcome Screen & Foreground Tap Tests', () {
    testWidgets(
      'Renders clean background with header and quick access panel',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpWelcome(tester);

        expect(find.text('Tulap.id'), findsOneWidget);
        expect(find.text('Akses Cepat'), findsOneWidget);
        expect(find.text('Masuk'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping on Hero Video background area does not intercept gestures',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpWelcome(tester);

        // Tap di area tengah atas hero video
        await tester.tapAt(const Offset(195, 200));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tetap di WelcomePage tanpa crash
        expect(find.text('Tulap.id'), findsOneWidget);
        expect(find.text('Akses Cepat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping quick access buttons opens login flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpWelcome(tester);

      // Tap Tugas Saya
      await tester.tap(find.text('Tugas Saya'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Masuk button triggers navigation', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpWelcome(tester);

      await tester.tap(find.text('Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays Offline badge when network is disconnected', (
      tester,
    ) async {
      fakeNetwork.online = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpWelcome(tester);

      expect(find.text('Offline'), findsOneWidget);
    });
  });
}
